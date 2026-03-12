import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/driver.dart';
import '../models/live_position.dart';
import '../models/race_control_message.dart';
import '../models/session.dart';
import '../models/weather.dart';
import '../models/meeting.dart';
import 'meetings_provider.dart';

class LiveEntry {
  final int position;
  final Driver driver;
  final String? interval; // gap to car ahead
  final String? gapToLeader;

  const LiveEntry({
    required this.position,
    required this.driver,
    this.interval,
    this.gapToLeader,
  });
}

// ──────────────────────────────────────────────
// Live-only providers (latest session)
// ──────────────────────────────────────────────

final liveSessionProvider = FutureProvider.autoDispose<Session?>((ref) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getLatestSession();
  if (data.isEmpty) return null;
  return Session.fromJson(data.first);
});

final livePollingProvider = StreamProvider.autoDispose<int>((ref) {
  int tick = 0;
  final controller = StreamController<int>();

  final timer = Timer.periodic(const Duration(seconds: 10), (_) {
    tick++;
    ref.invalidate(sessionPositionsProvider(null));
    ref.invalidate(sessionRaceControlProvider(null));
    if (tick % 3 == 0) {
      ref.invalidate(sessionWeatherProvider(null));
    }
    controller.add(tick);
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

final nextMeetingProvider = FutureProvider.autoDispose<Meeting?>((ref) async {
  final year = DateTime.now().year;
  final meetings = await ref.watch(meetingsProvider(year).future);
  final now = DateTime.now();
  for (final m in meetings) {
    if (m.dateStart.isAfter(now)) return m;
  }
  return null;
});

// ──────────────────────────────────────────────
// Shared providers (sessionKey: null = latest, int = specific)
// ──────────────────────────────────────────────

/// Drivers map for a session. null → latest session.
final sessionDriversProvider =
    FutureProvider.autoDispose.family<Map<int, Driver>, int?>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);

  int resolvedKey;
  if (sessionKey != null) {
    resolvedKey = sessionKey;
  } else {
    final session = await ref.watch(liveSessionProvider.future);
    if (session == null) return {};
    resolvedKey = session.sessionKey;
  }

  final data = await client.getDrivers(resolvedKey);
  return {
    for (final d in data)
      if ((d['driver_number'] as num?)?.toInt() != null)
        (d['driver_number'] as num).toInt(): Driver.fromJson(d),
  };
});

/// Positions + intervals merged. null → latest session.
final sessionPositionsProvider =
    FutureProvider.autoDispose.family<List<LiveEntry>, int?>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final drivers = await ref.watch(sessionDriversProvider(sessionKey).future);

  final positionsData = await client.getPositions(sessionKey: sessionKey);
  final intervalsData = await client.getIntervals(sessionKey: sessionKey);

  // Dedup positions: keep latest entry per driver
  final latestPositions = <int, LivePosition>{};
  for (final json in positionsData) {
    final p = LivePosition.fromJson(json);
    if (p.driverNumber <= 0) continue;
    final existing = latestPositions[p.driverNumber];
    if (existing == null ||
        (p.date != null &&
            (existing.date == null || p.date!.isAfter(existing.date!)))) {
      latestPositions[p.driverNumber] = p;
    }
  }

  // Dedup intervals: keep latest entry per driver
  final latestIntervals = <int, Map<String, dynamic>>{};
  for (final json in intervalsData) {
    final driverNum = (json['driver_number'] as num?)?.toInt() ?? 0;
    if (driverNum <= 0) continue;
    final date = json['date'] != null
        ? DateTime.tryParse(json['date'] as String)
        : null;
    final existing = latestIntervals[driverNum];
    if (existing == null ||
        (date != null &&
            (existing['date'] == null ||
                date.isAfter(
                    DateTime.tryParse(existing['date'] as String? ?? '') ??
                        DateTime(2000))))) {
      latestIntervals[driverNum] = json;
    }
  }

  final entries = <LiveEntry>[];
  for (final pos in latestPositions.values) {
    final driver = drivers[pos.driverNumber];
    if (driver == null) continue;

    final intervalData = latestIntervals[pos.driverNumber];
    String? interval;
    String? gapToLeader;
    if (intervalData != null) {
      final rawInterval = intervalData['interval'];
      final rawGap = intervalData['gap_to_leader'];
      interval = rawInterval != null ? '$rawInterval' : null;
      gapToLeader = rawGap != null ? '$rawGap' : null;
    }

    entries.add(LiveEntry(
      position: pos.position,
      driver: driver,
      interval: interval,
      gapToLeader: gapToLeader,
    ));
  }

  entries.sort((a, b) => a.position.compareTo(b.position));
  return entries;
});

/// Race control messages. null → latest session.
final sessionRaceControlProvider =
    FutureProvider.autoDispose.family<List<RaceControlMessage>, int?>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getRaceControl(sessionKey: sessionKey);
  final messages = data.map((j) => RaceControlMessage.fromJson(j)).toList();
  messages.sort((a, b) {
    if (a.date == null && b.date == null) return 0;
    if (a.date == null) return 1;
    if (b.date == null) return -1;
    return b.date!.compareTo(a.date!);
  });
  return messages;
});

/// Weather. null → latest session.
final sessionWeatherProvider =
    FutureProvider.autoDispose.family<Weather?, int?>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getWeather(sessionKey: sessionKey);
  if (data.isEmpty) return null;
  return Weather.fromJson(data.last);
});
