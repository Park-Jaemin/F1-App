import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/car_location.dart';
import '../models/driver.dart';
import '../models/session.dart';
import '../models/weather.dart';
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

class ReplayBufferNotifier extends StateNotifier<ReplayBufferState> {
  static const _chunkMinutes = 2;
  static const _sampleMs = 5000;
  static const _driverCallDelay = Duration(milliseconds: 2100);
  static const _bufferAhead = Duration(minutes: 3);
  static const _bufferBehind = Duration(minutes: 6);

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
      final driverNumbers = driversData
          .map((d) => (d['driver_number'] as num?)?.toInt() ?? 0)
          .where((n) => n > 0)
          .toList();

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
  return data.map((j) => Weather.fromJson(j)).toList();
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
