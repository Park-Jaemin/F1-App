import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/korean_locale.dart';
import 'meetings_provider.dart';
import '../models/session.dart';
import '../models/driver.dart';

class DriverStanding {
  final int positionCurrent;
  final int positionStart;
  final int driverNumber;
  final String broadcastName;
  final String nameAcronym;
  final String teamName;
  final String? teamColour;
  final int pointsCurrent;
  final int pointsStart;
  final String? countryCode;

  const DriverStanding({
    required this.positionCurrent,
    required this.positionStart,
    required this.driverNumber,
    required this.broadcastName,
    required this.nameAcronym,
    required this.teamName,
    this.teamColour,
    required this.pointsCurrent,
    required this.pointsStart,
    this.countryCode,
  });

  factory DriverStanding.fromJson(Map<String, dynamic> json) {
    final driverNum = (json['driver_number'] as num?)?.toInt() ?? 0;
    return DriverStanding(
      positionCurrent: (json['position_current'] as num?)?.toInt() ?? 0,
      positionStart: (json['position_start'] as num?)?.toInt() ?? 0,
      driverNumber: driverNum,
      broadcastName: json['broadcast_name'] as String? ?? (driverNum > 0 ? 'Driver #$driverNum' : 'Unknown'),
      nameAcronym: json['name_acronym'] as String? ?? (driverNum > 0 ? '$driverNum' : '???'),
      teamName: json['team_name'] as String? ?? 'Unknown Team',
      teamColour: json['team_colour'] as String?,
      pointsCurrent: (json['points_current'] as num?)?.toInt() ?? 0,
      pointsStart: (json['points_start'] as num?)?.toInt() ?? 0,
      countryCode: json['country_code'] as String?,
    );
  }

  String get flagEmoji => countryCodeToFlag(countryCode ?? '');
  
  // 순위 변동 계산 (양수: 상승, 음수: 하락)
  int get positionChange => (positionStart > 0 && positionCurrent > 0) ? positionStart - positionCurrent : 0;
}

class TeamStanding {
  final int position;
  final int positionStart;
  final String teamName;
  final String? teamColour;
  final int points;

  const TeamStanding({
    required this.position,
    required this.positionStart,
    required this.teamName,
    this.teamColour,
    required this.points,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json) {
    final position =
        (json['position'] ?? json['position_current'] ?? 0) as num?;
    final positionStart =
        (json['position_before'] ?? json['position_start'] ?? 0) as num?;
    final points = (json['points'] ?? json['points_current'] ?? 0) as num?;
    final teamName = (json['team_name'] ??
            json['constructor_name'] ??
            json['team'] ??
            'Unknown Team')
        as String;
    return TeamStanding(
      position: position?.toInt() ?? 0,
      positionStart: positionStart?.toInt() ?? 0,
      teamName: teamName,
      teamColour: json['team_colour'] as String?,
      points: points?.toInt() ?? 0,
    );
  }

  int get positionChange => (positionStart > 0 && position > 0) ? positionStart - position : 0;
}

final latestSessionKeyProvider =
    FutureProvider.family<int?, int>((ref, year) async {
  final meetings = await ref.watch(meetingsProvider(year).future);
  if (meetings.isEmpty) return null;

  final now = DateTime.now();
  final relevantMeetings = meetings.where((m) => m.dateStart.isBefore(now.add(const Duration(days: 1)))).toList();
  if (relevantMeetings.isEmpty) return null;

  final client = ref.read(openF1ClientProvider);

  for (final meeting in relevantMeetings.reversed) {
    final sessionsData = await client.getSessions(meeting.meetingKey);
    if (sessionsData.isEmpty) continue;

    final sessions = sessionsData.map((s) => Session.fromJson(s)).toList();
    sessions.sort((a, b) => b.dateStart.compareTo(a.dateStart));

    for (final session in sessions) {
      if (session.isRace && session.isCompleted) {
        return session.sessionKey;
      }
    }
    
    for (final session in sessions) {
      if (session.isCompleted) {
        return session.sessionKey;
      }
    }
  }

  try {
    final firstSessions = await client.getSessions(meetings.first.meetingKey);
    if (firstSessions.isNotEmpty) {
      return firstSessions.first['session_key'] as int?;
    }
  } catch (_) {}

  return null;
});

final driverStandingsProvider =
    FutureProvider.family<List<DriverStanding>, int>((ref, year) async {
  final sessionKey = await ref.watch(latestSessionKeyProvider(year).future);
  if (sessionKey == null) return [];

  final client = ref.read(openF1ClientProvider);
  
  // 1. 챔피언십 포인트 데이터 가져오기 (순위와 포인트 정보)
  final standingsData = await client.getChampionshipDrivers(sessionKey);
  if (standingsData.isEmpty) return [];

  // 2. 현재 세션의 드라이버 정보를 한 번에 가져와 driver_number로 매핑
  final driversData = await client.getDrivers(sessionKey);
  final driverMap = {
    for (final d in driversData)
      if ((d['driver_number'] as num?)?.toInt() != null)
        (d['driver_number'] as num).toInt(): Driver.fromJson(d),
  };

  // 3. 현재 세션에 없는 드라이버(시즌 중 시트 상실 등)만 개별 조회
  //    /drivers?driver_number=X 로 전체 이력을 가져온 뒤
  //    해당 연도의 meeting_key 목록과 교차해 올해 출전 기록 중 가장 최근 것을 사용
  final missingNums = standingsData
      .map((json) => (json['driver_number'] as num?)?.toInt() ?? 0)
      .where((n) => n > 0 && !driverMap.containsKey(n))
      .toSet();

  if (missingNums.isNotEmpty) {
    final meetings = await ref.watch(meetingsProvider(year).future);
    final yearMeetingKeys = meetings.map((m) => m.meetingKey).toSet();

    final futures = missingNums.map((driverNum) async {
      try {
        final list = await client.getDriversWithParams({
          'driver_number': driverNum,
        });
        // 올해 대회에 해당하는 기록만 필터링 후 가장 마지막(최신) 사용
        final inYear = list.where((d) {
          final mk = (d['meeting_key'] as num?)?.toInt();
          return mk != null && yearMeetingKeys.contains(mk);
        }).toList();
        if (inYear.isNotEmpty) {
          driverMap[driverNum] = Driver.fromJson(inYear.last);
        }
      } catch (_) {}
    });
    await Future.wait(futures);
  }

  final List<DriverStanding> standings = [];
  for (final json in standingsData) {
    final driverNum = (json['driver_number'] as num?)?.toInt() ?? 0;
    final driver = driverMap[driverNum];

    standings.add(DriverStanding.fromJson({
      ...json,
      if (driver != null) ...{
        'broadcast_name': driver.broadcastName,
        'name_acronym': driver.nameAcronym,
        'team_name': driver.teamName,
        'team_colour': driver.teamColour,
        'country_code': driver.countryCode,
      },
    }));
  }

  standings.sort((a, b) => a.positionCurrent.compareTo(b.positionCurrent));
  return standings.where((s) => s.positionCurrent > 0).toList();
});

final teamStandingsProvider =
    FutureProvider.family<List<TeamStanding>, int>((ref, year) async {
  final sessionKey = await ref.watch(latestSessionKeyProvider(year).future);
  if (sessionKey == null) return [];

  final client = ref.read(openF1ClientProvider);
  
  final data = await client.getChampionshipConstructors(sessionKey);
  
  final drivers = await ref.watch(driverStandingsProvider(year).future);
  final teamColourMap = {
    for (final d in drivers) d.teamName: d.teamColour,
  };

  List<TeamStanding> buildFromDrivers() {
    final teamPoints = <String, int>{};
    for (final driver in drivers) {
      if (driver.teamName != 'Unknown Team') {
        teamPoints[driver.teamName] =
            (teamPoints[driver.teamName] ?? 0) + driver.pointsCurrent;
      }
    }
    final standings = teamPoints.entries
        .map((e) => TeamStanding(
              position: 0,
              positionStart: 0,
              teamName: e.key,
              teamColour: teamColourMap[e.key],
              points: e.value,
            ))
        .toList();
    standings.sort((a, b) => b.points.compareTo(a.points));
    return standings
        .asMap()
        .entries
        .map((e) => TeamStanding(
              position: e.key + 1,
              positionStart: 0,
              teamName: e.value.teamName,
              teamColour: teamColourMap[e.value.teamName],
              points: e.value.points,
            ))
        .toList();
  }

  if (data.isEmpty) {
    return buildFromDrivers();
  }

  var standings = data.map((json) {
    final teamName = (json['team_name'] ?? json['constructor_name'] ?? 'Unknown Team') as String;
    return TeamStanding.fromJson({
      ...json,
      if (teamColourMap.containsKey(teamName))
        'team_colour': teamColourMap[teamName],
    });
  }).toList();

  final knownCount = standings
      .where((s) => s.teamName.trim().isNotEmpty && s.teamName != 'Unknown Team')
      .length;
  if (knownCount == 0) {
    return buildFromDrivers();
  }

  final computed = buildFromDrivers();
  if (computed.isNotEmpty) {
    final used = <String>{
      for (final s in standings)
        if (s.teamName.trim().isNotEmpty && s.teamName != 'Unknown Team')
          s.teamName
    };
    final pointsToTeams = <int, List<TeamStanding>>{};
    for (final s in computed) {
      pointsToTeams.putIfAbsent(s.points, () => []).add(s);
    }

    standings = standings.map((s) {
      final name = s.teamName.trim();
      if (name.isNotEmpty && name != 'Unknown Team') return s;

      final candidates = pointsToTeams[s.points] ?? const <TeamStanding>[];
      final candidate = candidates.firstWhere(
        (c) => !used.contains(c.teamName),
        orElse: () => const TeamStanding(
          position: 0,
          positionStart: 0,
          teamName: 'Unknown Team',
          points: 0,
        ),
      );

      if (candidate.teamName == 'Unknown Team') return s;
      used.add(candidate.teamName);
      return TeamStanding(
        position: s.position > 0 ? s.position : candidate.position,
        positionStart: s.positionStart,
        teamName: candidate.teamName,
        teamColour: candidate.teamColour,
        points: s.points,
      );
    }).toList();
  }

  standings.sort((a, b) => a.position.compareTo(b.position));
  return standings.where((s) => s.position > 0).toList();
});
