import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';
import '../models/lap.dart';
import '../models/pit_stop.dart';
import '../models/session_result.dart';
import '../models/stint.dart';
import 'meetings_provider.dart';

final sessionDriversProvider =
    FutureProvider.family<List<Driver>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getDrivers(sessionKey);
  return data.map((json) => Driver.fromJson(json)).toList();
});

final sessionResultsProvider =
    FutureProvider.family<List<SessionResult>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  // sessionDriversProvider 캐시를 재사용해 중복 API 호출 방지
  final resultData = await client.getSessionResult(sessionKey);
  final drivers = await ref.watch(sessionDriversProvider(sessionKey).future);

  final driverMap = <int, Driver>{
    for (final d in drivers) d.driverNumber: d,
  };

  final results = resultData.map((json) {
    final driverNum = (json['driver_number'] as num?)?.toInt() ?? 0;
    final driver = driverMap[driverNum];
    
    if (json['grid_position'] != null) {
      debugPrint('Driver $driverNum has grid_position: ${json['grid_position']}');
    }

    return SessionResult.fromJson({
      ...json,
      if (driver != null) ...{
        'broadcast_name': driver.broadcastName,
        'name_acronym': driver.nameAcronym,
        'team_name': driver.teamName,
        'team_colour': driver.teamColour,
        'headshot_url': driver.headshotUrl,
      },
    });
  }).toList();

  results.sort((a, b) {
    // 1. 정상 순위(position > 0)가 있는 경우 우선 정렬
    if (a.position > 0 && b.position > 0) {
      return a.position.compareTo(b.position);
    }
    if (a.position > 0) return -1;
    if (b.position > 0) return 1;

    // 2. 순위가 없는 경우(0 또는 null) 상태별 정렬 (NC -> DNF -> DSQ -> DNS -> DNQ 순)
    int getStatusWeight(SessionResult r) {
      if (r.nc) return 1;
      if (r.dnf) return 2;
      if (r.dsq) return 3;
      if (r.dns) return 4;
      if (r.dnq) return 5;
      return 6;
    }

    return getStatusWeight(a).compareTo(getStatusWeight(b));
  });

  return results;
});

final driverLapsProvider =
    FutureProvider.family<List<Lap>, ({int sessionKey, int driverNumber})>(
        (ref, params) async {
  final client = ref.read(openF1ClientProvider);
  final data =
      await client.getLaps(params.sessionKey, params.driverNumber);
  final laps = data.map((json) => Lap.fromJson(json)).toList();
  laps.sort((a, b) => a.lapNumber.compareTo(b.lapNumber));
  return laps;
});

final pitStopsProvider =
    FutureProvider.family<List<PitStop>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getPitStops(sessionKey);
  final stops = data.map((json) => PitStop.fromJson(json)).toList();
  stops.sort((a, b) {
    final driverCmp = a.driverNumber.compareTo(b.driverNumber);
    if (driverCmp != 0) return driverCmp;
    return a.lapNumber.compareTo(b.lapNumber);
  });
  return stops;
});

final stintsProvider =
    FutureProvider.family<List<Stint>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getStints(sessionKey);
  final stints = data.map((json) => Stint.fromJson(json)).toList();
  stints.sort((a, b) {
    final driverCmp = a.driverNumber.compareTo(b.driverNumber);
    if (driverCmp != 0) return driverCmp;
    return a.stintNumber.compareTo(b.stintNumber);
  });
  return stints;
});

/// 세션 내 각 드라이버의 베스트 랩타임 (driverNumber → bestLapDuration)
final sessionBestLapsProvider =
    FutureProvider.family<Map<int, double>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getAllLaps(sessionKey);
  final laps = data.map((json) => Lap.fromJson(json)).toList();

  final bestLaps = <int, double>{};
  for (final lap in laps) {
    if (lap.lapDuration == null || lap.isPitOutLap) continue;
    final current = bestLaps[lap.driverNumber];
    if (current == null || lap.lapDuration! < current) {
      bestLaps[lap.driverNumber] = lap.lapDuration!;
    }
  }
  return bestLaps;
});

final selectedDriverNumberProvider = StateProvider<int?>((ref) => null);

/// 특정 그랑프리의 포디엄 결과 (상위 3명)
final podiumProvider =
    FutureProvider.family<List<SessionResult>, int>((ref, meetingKey) async {
  final session = await ref.watch(raceSessionProvider(meetingKey).future);
  if (session == null) return [];
  final results =
      await ref.watch(sessionResultsProvider(session.sessionKey).future);
  return results
      .where((r) => !r.dnf && !r.dns && !r.dsq && r.position > 0)
      .take(3)
      .toList();
});

/// 세션별 상위 3명 결과 (탭 선택 시에만 호출)
final sessionTop3Provider =
    FutureProvider.family<List<SessionResult>, int>((ref, sessionKey) async {
  final results = await ref.watch(sessionResultsProvider(sessionKey).future);
  return results
      .where((r) => !r.dnf && !r.dns && !r.dsq && r.position > 0)
      .take(3)
      .toList();
});
