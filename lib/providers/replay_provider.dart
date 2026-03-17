import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/openf1_client.dart';
import '../models/car_location.dart';
import '../models/driver.dart';
import '../models/session.dart';
import '../models/weather.dart';
import '../models/pit_stop.dart';
import 'meetings_provider.dart';

class ReplayBufferState {
  final Map<int, List<CarLocation>> locations;
  final DateTime? sessionStart;
  final DateTime? sessionEnd;
  final DateTime? loadedUntil;
  final bool isLoading;
  final String? error;

  const ReplayBufferState({
    required this.locations,
    this.sessionStart,
    this.sessionEnd,
    this.loadedUntil,
    this.isLoading = false,
    this.error,
  });

  factory ReplayBufferState.loading() =>
      const ReplayBufferState(locations: {}, isLoading: true);
}

final replayBufferProvider = StateNotifierProvider.autoDispose
    .family<ReplayBufferNotifier, ReplayBufferState, int>(
        (ref, sessionKey) {
  return ReplayBufferNotifier(ref, sessionKey);
});

class ReplayTimelineEvent {
  final DateTime time;
  final String title;
  final String? detail;
  final int? driverNumber;
  final int? lapNumber;
  final String type;

  const ReplayTimelineEvent({
    required this.time,
    required this.title,
    this.detail,
    this.driverNumber,
    this.lapNumber,
    required this.type,
  });
}

class ReplaySessionRange {
  final DateTime start;
  final DateTime end;

  const ReplaySessionRange({required this.start, required this.end});
}

class PositionSample {
  final DateTime time;
  final int position;

  const PositionSample({required this.time, required this.position});
}

class ReplayBufferNotifier extends StateNotifier<ReplayBufferState> {
  static const _chunkMinutes = 1;
  static const _sampleMs = 30000;
  static const _driverCallDelay = Duration(milliseconds: 2100);
  static const _bufferAhead = Duration(seconds: 30);
  static const _bufferBehind = Duration(minutes: 2);
  static const _maxDrivers = 3;

  final Ref ref;
  final int sessionKey;
  bool _disposed = false;
  DateTime? _playbackTime;
  Completer<void>? _bufferWaiter;

  ReplayBufferNotifier(this.ref, this.sessionKey)
      : super(ReplayBufferState.loading()) {
    ref.onDispose(() => _disposed = true);
    _load();
  }

  void updatePlaybackTime(DateTime time) {
    _playbackTime = time;
    _pruneOld(time);
    if (_bufferWaiter != null && _shouldLoadMoreFor(time)) {
      _bufferWaiter!.complete();
      _bufferWaiter = null;
    }
  }

  Future<void> _load() async {
    try {
      final client = ref.read(openF1ClientProvider);
      final sessionData = await client.getSessionsByKey(sessionKey);
      if (sessionData.isEmpty) {
        state = const ReplayBufferState(
          locations: {},
          isLoading: false,
          error: '세션 정보를 찾을 수 없습니다',
        );
        return;
      }
      final session = Session.fromJson(sessionData.first);
      final start = session.dateStart;
      final end = session.dateEnd ?? session.dateStart.add(const Duration(hours: 2));

      final driversData = await client.getDrivers(sessionKey);
      final allDrivers = driversData
          .map((d) => (d['driver_number'] as num?)?.toInt() ?? 0)
          .where((n) => n > 0)
          .toList();

      final topDrivers = await _selectTopDrivers(client, sessionKey);
      final driverNumbers =
          topDrivers.isNotEmpty ? topDrivers : allDrivers.take(_maxDrivers).toList();

      final locations = <int, List<CarLocation>>{};
      var chunkStart = start;
      var firstChunk = true;
      while (chunkStart.isBefore(end) && !_disposed) {
        if (!firstChunk) {
          if (_playbackTime == null) {
            await _waitForBufferRoom();
          } else if (!_shouldLoadMoreFor(_playbackTime!)) {
            await _waitForBufferRoom();
          }
        }
        firstChunk = false;

        final chunkEnd = chunkStart.add(const Duration(minutes: _chunkMinutes));
        final boundedEnd = chunkEnd.isAfter(end) ? end : chunkEnd;

        for (var idx = 0; idx < driverNumbers.length; idx++) {
          final driverNumber = driverNumbers[idx];
          if (_disposed) break;
          if (idx > 0) {
            await Future.delayed(_driverCallDelay);
          }
          try {
            final data = await client.getLocationForDriver(
              sessionKey,
              driverNumber,
              start: chunkStart,
              end: boundedEnd,
            );
            final sampled = _downsample(
              data
                  .map((json) => CarLocation.fromJson(json))
                  .where((loc) => loc.driverNumber > 0)
                  .toList()
                ..sort((a, b) => a.date.compareTo(b.date)),
              _sampleMs,
            );
            if (sampled.isEmpty) continue;

            final list = locations.putIfAbsent(driverNumber, () => []);
            if (list.isNotEmpty) {
              final lastDate = list.last.date;
              list.addAll(sampled.where((loc) => loc.date.isAfter(lastDate)));
            } else {
              list.addAll(sampled);
            }
          } catch (_) {
            continue;
          }
        }

        state = ReplayBufferState(
          locations: locations,
          sessionStart: start,
          sessionEnd: end,
          loadedUntil: boundedEnd,
          isLoading: boundedEnd.isBefore(end),
        );
        if (_playbackTime != null) {
          _pruneOld(_playbackTime!);
        }

        chunkStart = boundedEnd;
      }
    } catch (e) {
      if (!_disposed) {
        state = ReplayBufferState(
          locations: state.locations,
          sessionStart: state.sessionStart,
          sessionEnd: state.sessionEnd,
          loadedUntil: state.loadedUntil,
          isLoading: false,
          error: e.toString(),
        );
      }
    }
  }

  Future<List<int>> _selectTopDrivers(
      OpenF1Client client, int sessionKey) async {
    try {
      final data = await client.getSessionResult(sessionKey);
      final entries = <({int driver, int position})>[];
      for (final json in data) {
        final driverNum = (json['driver_number'] as num?)?.toInt() ?? 0;
        final position = (json['position'] as num?)?.toInt() ?? 0;
        if (driverNum > 0 && position > 0) {
          entries.add((driver: driverNum, position: position));
        }
      }
      entries.sort((a, b) => a.position.compareTo(b.position));
      return entries.take(_maxDrivers).map((e) => e.driver).toList();
    } catch (_) {
      return [];
    }
  }

  bool _shouldLoadMoreFor(DateTime time) {
    final loadedUntil = state.loadedUntil;
    if (loadedUntil == null) return true;
    return loadedUntil.isBefore(time.add(_bufferAhead));
  }

  Future<void> _waitForBufferRoom() async {
    if (_disposed) return;
    _bufferWaiter ??= Completer<void>();
    await _bufferWaiter!.future;
  }

  void _pruneOld(DateTime time) {
    final threshold = time.subtract(_bufferBehind);
    var changed = false;
    final next = <int, List<CarLocation>>{};
    for (final entry in state.locations.entries) {
      final list = entry.value;
      final firstKeep =
          list.indexWhere((loc) => !loc.date.isBefore(threshold));
      if (firstKeep == -1) {
        changed = true;
        continue;
      }
      if (firstKeep == 0) {
        next[entry.key] = list;
      } else {
        next[entry.key] = list.sublist(firstKeep);
        changed = true;
      }
    }
    if (changed) {
      state = ReplayBufferState(
        locations: next,
        sessionStart: state.sessionStart,
        sessionEnd: state.sessionEnd,
        loadedUntil: state.loadedUntil,
        isLoading: state.isLoading,
        error: state.error,
      );
    }
  }
}

final replayTrackOutlineProvider = FutureProvider.autoDispose
    .family<List<CarLocation>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final sessions = await client.getSessionsByKey(sessionKey);
  if (sessions.isEmpty) return [];
  final session = Session.fromJson(sessions.first);
  final start = session.dateStart;
  final end = start.add(const Duration(minutes: 3));

  final driver = await _selectOutlineDriver(client, sessionKey);
  if (driver == null) return [];

  final data = await client.getLocationForDriver(
    sessionKey,
    driver,
    start: start,
    end: end,
  );
  final list = data
      .map((json) => CarLocation.fromJson(json))
      .where((loc) => loc.driverNumber > 0)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return _downsample(list, 2000);
});

DateTime _normalizeUtc(DateTime date) {
  if (date.isUtc) return date;
  return DateTime.utc(
    date.year,
    date.month,
    date.day,
    date.hour,
    date.minute,
    date.second,
    date.millisecond,
    date.microsecond,
  );
}

DateTime? _parseOpenF1Date(String? value) {
  if (value == null || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return _normalizeUtc(parsed);
}

final replaySessionRangeProvider = FutureProvider.autoDispose
    .family<ReplaySessionRange?, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final sessions = await client.getSessionsByKey(sessionKey);
  if (sessions.isEmpty) return null;
  final session = Session.fromJson(sessions.first);
  final start = _normalizeUtc(session.dateStart);
  final end = session.dateEnd != null
      ? _normalizeUtc(session.dateEnd!)
      : start.add(const Duration(hours: 2));
  return ReplaySessionRange(start: start, end: end);
});

final replayPositionsProvider = FutureProvider.autoDispose
    .family<Map<int, List<PositionSample>>, int>((ref, sessionKey) async {
  const sampleMs = 10000;
  final client = ref.read(openF1ClientProvider);
  final data = await client.getPositions(
    sessionKey: sessionKey,
  );

  final map = <int, List<PositionSample>>{};
  for (final json in data) {
    final dateStr = json['date'] as String?;
    final date = _parseOpenF1Date(dateStr);
    if (date == null) continue;
    final driverNum = (json['driver_number'] as num?)?.toInt() ?? 0;
    final position = (json['position'] as num?)?.toInt() ?? 0;
    if (driverNum <= 0 || position <= 0) continue;
    map.putIfAbsent(driverNum, () => []).add(
          PositionSample(time: date, position: position),
        );
  }

  for (final entry in map.entries) {
    entry.value.sort((a, b) => a.time.compareTo(b.time));
    map[entry.key] = _downsamplePositions(entry.value, sampleMs);
  }

  return map;
});

List<PositionSample> _downsamplePositions(
  List<PositionSample> list,
  int sampleMs,
) {
  if (list.isEmpty) return list;
  final result = <PositionSample>[];
  DateTime? last;
  for (final item in list) {
    if (last == null ||
        item.time.difference(last).inMilliseconds >= sampleMs) {
      result.add(item);
      last = item.time;
    }
  }
  return result;
}

Future<int?> _selectOutlineDriver(OpenF1Client client, int sessionKey) async {
  try {
    final results = await client.getSessionResult(sessionKey);
    for (final json in results) {
      final position = (json['position'] as num?)?.toInt() ?? 0;
      final driver = (json['driver_number'] as num?)?.toInt() ?? 0;
      if (position == 1 && driver > 0) return driver;
    }
  } catch (_) {}
  try {
    final drivers = await client.getDrivers(sessionKey);
    for (final d in drivers) {
      final driver = (d['driver_number'] as num?)?.toInt() ?? 0;
      if (driver > 0) return driver;
    }
  } catch (_) {}
  return null;
}

final replayTimelineProvider = FutureProvider.autoDispose
    .family<List<ReplayTimelineEvent>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final events = <ReplayTimelineEvent>[];

  try {
    final raceControl = await client.getRaceControl(sessionKey: sessionKey);
    for (final json in raceControl) {
      final dateStr = json['date'] as String?;
      final date = _parseOpenF1Date(dateStr);
      if (date == null) continue;
      final category =
          (json['category'] ?? json['flag'] ?? 'Race Control') as String;
      final message = json['message'] as String? ?? '';
      final lap = (json['lap_number'] as num?)?.toInt();
      events.add(ReplayTimelineEvent(
        time: date,
        title: category,
        detail: message.isEmpty ? null : message,
        lapNumber: lap,
        type: 'race_control',
      ));
    }
  } catch (_) {}

  try {
    final pitData = await client.getPitStops(sessionKey);
    final pitStops = pitData.map((j) => PitStop.fromJson(j));
    for (final pit in pitStops) {
      final date = pit.date != null ? _normalizeUtc(pit.date!) : null;
      if (date == null) continue;
      events.add(ReplayTimelineEvent(
        time: date,
        title: 'Pit Stop',
        detail: 'Lap ${pit.lapNumber} · ${pit.formattedDuration}',
        driverNumber: pit.driverNumber,
        lapNumber: pit.lapNumber,
        type: 'pit',
      ));
    }
  } catch (_) {}

  events.sort((a, b) => a.time.compareTo(b.time));
  return events;
});

/// Drivers for the replay session
final replayDriversProvider = FutureProvider.autoDispose
    .family<Map<int, Driver>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getDrivers(sessionKey);
  return {
    for (final d in data)
      if ((d['driver_number'] as num?)?.toInt() != null)
        (d['driver_number'] as num).toInt(): Driver.fromJson(d),
  };
});

/// All weather data for the session, time-sorted.
final replayWeatherProvider = FutureProvider.autoDispose
    .family<List<Weather>, int>((ref, sessionKey) async {
  final client = ref.read(openF1ClientProvider);
  final data = await client.getWeather(sessionKey: sessionKey);
  return data.map((j) => Weather.fromJson(j)).map((weather) {
    return Weather(
      date: weather.date != null ? _normalizeUtc(weather.date!) : null,
      airTemperature: weather.airTemperature,
      trackTemperature: weather.trackTemperature,
      humidity: weather.humidity,
      rainfall: weather.rainfall,
      windSpeed: weather.windSpeed,
      windDirection: weather.windDirection,
    );
  }).toList();
});

List<CarLocation> _downsample(List<CarLocation> list, int sampleMs) {
  if (list.isEmpty) return list;
  final result = <CarLocation>[];
  DateTime? last;
  for (final loc in list) {
    if (last == null ||
        loc.date.difference(last).inMilliseconds >= sampleMs) {
      result.add(loc);
      last = loc.date;
    }
  }
  return result;
}

/// Represents a single driver's interpolated position at a given time.
class ReplayCarState {
  final int driverNumber;
  final Driver? driver;
  final double x;
  final double y;

  const ReplayCarState({
    required this.driverNumber,
    this.driver,
    required this.x,
    required this.y,
  });
}

/// Given a sorted location list and a target time, find the interpolated (x, y).
ReplayCarState? interpolateAt(
  List<CarLocation> locs,
  DateTime time,
  int driverNumber,
  Driver? driver,
) {
  if (locs.isEmpty) return null;

  // Before first data point
  if (time.isBefore(locs.first.date)) {
    return ReplayCarState(
        driverNumber: driverNumber, driver: driver, x: locs.first.x, y: locs.first.y);
  }
  // After last data point
  if (time.isAfter(locs.last.date)) {
    return ReplayCarState(
        driverNumber: driverNumber, driver: driver, x: locs.last.x, y: locs.last.y);
  }

  // Binary search for the two surrounding points
  int lo = 0, hi = locs.length - 1;
  while (lo < hi - 1) {
    final mid = (lo + hi) ~/ 2;
    if (locs[mid].date.isBefore(time)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }

  final a = locs[lo];
  final b = locs[hi];
  final totalMs = b.date.difference(a.date).inMilliseconds;
  if (totalMs == 0) {
    return ReplayCarState(driverNumber: driverNumber, driver: driver, x: a.x, y: a.y);
  }

  final t = time.difference(a.date).inMilliseconds / totalMs;
  return ReplayCarState(
    driverNumber: driverNumber,
    driver: driver,
    x: a.x + (b.x - a.x) * t,
    y: a.y + (b.y - a.y) * t,
  );
}

/// Find the weather at a given time from a sorted weather list.
Weather? weatherAtTime(List<Weather> weatherList, DateTime time) {
  if (weatherList.isEmpty) return null;
  Weather? result;
  for (final w in weatherList) {
    if (w.date != null && w.date!.isAfter(time)) break;
    result = w;
  }
  return result ?? weatherList.first;
}
