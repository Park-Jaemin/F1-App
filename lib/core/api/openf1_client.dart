import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'endpoints.dart';

class OpenF1Client {
  late final Dio _dio;
  final _cache = <String, _CacheEntry<List<Map<String, dynamic>>>>{};
  final _inflight = <String, Future<List<Map<String, dynamic>>>>{};
  final _limiter = _RequestLimiter(
    maxConcurrent: 1,
    minInterval: const Duration(milliseconds: 250),
  );

  OpenF1Client() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_RetryInterceptor(_dio));
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('[OpenF1] $obj'),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getMeetings(int year) async {
    return _getList(
      ApiEndpoints.meetings,
      query: {'year': year},
      ttl: const Duration(hours: 12),
    );
  }

  Future<List<Map<String, dynamic>>> getSessions(int meetingKey) async {
    return _getList(
      ApiEndpoints.sessions,
      query: {'meeting_key': meetingKey},
      ttl: const Duration(hours: 6),
    );
  }

  Future<List<Map<String, dynamic>>> getSessionsByKey(int sessionKey) async {
    return _getList(
      ApiEndpoints.sessions,
      query: {'session_key': sessionKey},
      ttl: const Duration(hours: 6),
    );
  }

  Future<List<Map<String, dynamic>>> getSessionResult(int sessionKey) async {
    return _getList(
      ApiEndpoints.sessionResult,
      query: {'session_key': sessionKey},
      ttl: const Duration(minutes: 2),
    );
  }

  Future<List<Map<String, dynamic>>> getDrivers(int sessionKey) async {
    return _getList(
      ApiEndpoints.drivers,
      query: {'session_key': sessionKey},
      ttl: const Duration(minutes: 10),
    );
  }

  Future<List<Map<String, dynamic>>> getDriversWithParams(
      Map<String, dynamic> params) async {
    return _getList(
      ApiEndpoints.drivers,
      query: params,
      ttl: const Duration(minutes: 10),
    );
  }

  Future<List<Map<String, dynamic>>> getLaps(
      int sessionKey, int driverNumber) async {
    return _getList(
      ApiEndpoints.laps,
      query: {
        'session_key': sessionKey,
        'driver_number': driverNumber,
      },
      ttl: const Duration(minutes: 2),
    );
  }

  Future<List<Map<String, dynamic>>> getAllLaps(int sessionKey) async {
    return _getList(
      ApiEndpoints.laps,
      query: {'session_key': sessionKey},
      ttl: const Duration(minutes: 2),
    );
  }

  Future<List<Map<String, dynamic>>> getPitStops(int sessionKey) async {
    return _getList(
      ApiEndpoints.pit,
      query: {'session_key': sessionKey},
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<Map<String, dynamic>>> getStints(int sessionKey) async {
    return _getList(
      ApiEndpoints.stints,
      query: {'session_key': sessionKey},
      ttl: const Duration(minutes: 5),
    );
  }

  Future<List<Map<String, dynamic>>> getChampionshipDrivers(
      int sessionKey) async {
    return _getList(
      ApiEndpoints.championshipDrivers,
      query: {'session_key': sessionKey},
      ttl: const Duration(minutes: 10),
    );
  }

  Future<List<Map<String, dynamic>>> getChampionshipConstructors(
      int sessionKey) async {
    return _getList(
      ApiEndpoints.championshipConstructors,
      query: {'session_key': sessionKey},
      ttl: const Duration(minutes: 10),
    );
  }

  Future<List<Map<String, dynamic>>> getLatestSession() async {
    return _getList(
      ApiEndpoints.sessions,
      query: {'session_key': 'latest'},
      ttl: const Duration(seconds: 30),
    );
  }

  /// [sessionKey] — `null` means "latest" (live), otherwise a specific session.
  Future<List<Map<String, dynamic>>> getPositions({int? sessionKey}) async {
    final key = sessionKey ?? 'latest';
    return _getList(
      ApiEndpoints.position,
      query: {'session_key': key},
      ttl: sessionKey != null
          ? const Duration(hours: 1)
          : const Duration(seconds: 15),
    );
  }

  Future<List<Map<String, dynamic>>> getIntervals({int? sessionKey}) async {
    final key = sessionKey ?? 'latest';
    return _getList(
      ApiEndpoints.intervals,
      query: {'session_key': key},
      ttl: sessionKey != null
          ? const Duration(hours: 1)
          : const Duration(seconds: 15),
    );
  }

  Future<List<Map<String, dynamic>>> getRaceControl({int? sessionKey}) async {
    final key = sessionKey ?? 'latest';
    return _getList(
      ApiEndpoints.raceControl,
      query: {'session_key': key},
      ttl: sessionKey != null
          ? const Duration(hours: 1)
          : const Duration(seconds: 15),
    );
  }

  Future<List<Map<String, dynamic>>> getWeather({int? sessionKey}) async {
    final key = sessionKey ?? 'latest';
    return _getList(
      ApiEndpoints.weather,
      query: {'session_key': key},
      ttl: sessionKey != null
          ? const Duration(hours: 1)
          : const Duration(seconds: 30),
    );
  }

  /// Fetch car location data for a specific session and driver.
  /// Returns x, y, z coordinates over time.
  Future<List<Map<String, dynamic>>> getLocationForDriver(
      int sessionKey, int driverNumber,
      {DateTime? start, DateTime? end}) async {
    final query = <String, dynamic>{
      'session_key': sessionKey,
      'driver_number': driverNumber,
    };
    if (start != null) {
      query['date>'] = start.toIso8601String();
    }
    if (end != null) {
      query['date<'] = end.toIso8601String();
    }
    return _getList(
      ApiEndpoints.location,
      query: query,
      ttl: const Duration(hours: 2),
    );
  }

  /// Fetch location data for all drivers (for building circuit shape).
  /// Uses a single driver's data to draw the track outline.
  Future<List<Map<String, dynamic>>> getLocationAll(int sessionKey) async {
    return _getList(
      ApiEndpoints.location,
      query: {'session_key': sessionKey},
      ttl: const Duration(hours: 2),
    );
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, dynamic>? query,
    Duration ttl = const Duration(minutes: 2),
  }) async {
    final key = _cacheKey(path, query);
    final now = DateTime.now();
    final cached = _cache[key];
    if (cached != null && cached.expiresAt.isAfter(now)) {
      return cached.data;
    }

    final inflight = _inflight[key];
    if (inflight != null) return inflight;

    final future = _limiter.withPermit(() async {
      final response = await _dio.get(
        path,
        queryParameters: query,
      );
      final list = _parseList(response.data);
      if (ttl > Duration.zero) {
        _cache[key] = _CacheEntry(list, DateTime.now().add(ttl));
      }
      return list;
    });

    _inflight[key] = future;
    return future.whenComplete(() {
      _inflight.remove(key);
    });
  }

  String _cacheKey(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return path;
    final keys = query.keys.toList()..sort();
    final params = keys.map((k) => '$k=${query[k]}').join('&');
    return '$path?$params';
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}

/// 429 Too Many Requests에 대해 최대 3회 지수 백오프 재시도
class _RetryInterceptor extends Interceptor {
  final Dio dio;
  _RetryInterceptor(this.dio);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    if (response?.statusCode == 429) {
      final attempt = (err.requestOptions.extra['_retryCount'] as int?) ?? 0;
      if (attempt < 3) {
        final delay = Duration(milliseconds: 500 * (1 << attempt)); // 0.5s, 1s, 2s
        await Future.delayed(delay);
        try {
          final options = err.requestOptions;
          options.extra['_retryCount'] = attempt + 1;
          final retryResponse = await dio.fetch(options);
          return handler.resolve(retryResponse);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    handler.next(err);
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  const _CacheEntry(this.data, this.expiresAt);
}

class _RequestLimiter {
  final int maxConcurrent;
  final Duration minInterval;
  int _inFlight = 0;
  final Queue<Completer<void>> _queue = Queue<Completer<void>>();
  DateTime _lastStart = DateTime.fromMillisecondsSinceEpoch(0);

  _RequestLimiter({
    required this.maxConcurrent,
    this.minInterval = Duration.zero,
  });

  Future<void> acquire() {
    if (_inFlight < maxConcurrent) {
      _inFlight++;
      return Future.value();
    }
    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      final completer = _queue.removeFirst();
      completer.complete();
      return;
    }
    if (_inFlight > 0) {
      _inFlight -= 1;
    }
  }

  Future<T> withPermit<T>(Future<T> Function() action) async {
    await acquire();
    try {
      if (minInterval > Duration.zero) {
        final now = DateTime.now();
        final elapsed = now.difference(_lastStart);
        if (elapsed < minInterval) {
          await Future.delayed(minInterval - elapsed);
        }
        _lastStart = DateTime.now();
      }
      return await action();
    } finally {
      release();
    }
  }
}
