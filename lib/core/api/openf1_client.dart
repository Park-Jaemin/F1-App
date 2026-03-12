import 'package:dio/dio.dart';
import 'endpoints.dart';

class OpenF1Client {
  late final Dio _dio;

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
    final response = await _dio.get(
      ApiEndpoints.meetings,
      queryParameters: {'year': year},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getSessions(int meetingKey) async {
    final response = await _dio.get(
      ApiEndpoints.sessions,
      queryParameters: {'meeting_key': meetingKey},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getSessionResult(int sessionKey) async {
    final response = await _dio.get(
      ApiEndpoints.sessionResult,
      queryParameters: {'session_key': sessionKey},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getDrivers(int sessionKey) async {
    final response = await _dio.get(
      ApiEndpoints.drivers,
      queryParameters: {'session_key': sessionKey},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getDriversWithParams(
      Map<String, dynamic> params) async {
    final response = await _dio.get(
      ApiEndpoints.drivers,
      queryParameters: params,
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getLaps(
      int sessionKey, int driverNumber) async {
    final response = await _dio.get(
      ApiEndpoints.laps,
      queryParameters: {
        'session_key': sessionKey,
        'driver_number': driverNumber,
      },
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getAllLaps(int sessionKey) async {
    final response = await _dio.get(
      ApiEndpoints.laps,
      queryParameters: {'session_key': sessionKey},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getPitStops(int sessionKey) async {
    final response = await _dio.get(
      ApiEndpoints.pit,
      queryParameters: {'session_key': sessionKey},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getStints(int sessionKey) async {
    final response = await _dio.get(
      ApiEndpoints.stints,
      queryParameters: {'session_key': sessionKey},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getChampionshipDrivers(
      int sessionKey) async {
    final response = await _dio.get(
      ApiEndpoints.championshipDrivers,
      queryParameters: {'session_key': sessionKey},
    );
    return _parseList(response.data);
  }

  Future<List<Map<String, dynamic>>> getChampionshipConstructors(
      int sessionKey) async {
    final response = await _dio.get(
      ApiEndpoints.championshipConstructors,
      queryParameters: {'session_key': sessionKey},
    );
    return _parseList(response.data);
  }

  List<Map<String, dynamic>> _parseList(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
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
