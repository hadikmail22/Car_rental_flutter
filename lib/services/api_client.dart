import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  // In memory until init() runs, then saved on the phone,
  // so the session survives closing the app.
  static CookieJar _cookieJar = CookieJar();

  static final Dio dio = _createDio();

  /// Called once in main() before runApp.
  /// Replaces the memory cookie jar with one stored on disk.
  static Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      _cookieJar = PersistCookieJar(
        storage: FileStorage('${directory.path}/.cookies/'),
      );
    } catch (_) {
      // If storage is unavailable, keep the memory jar.
      // The app still works, the user just logs in each time.
    }

    // The cookie manager must be the first interceptor,
    // so every other interceptor sees the session cookie.
    dio.interceptors.removeWhere((interceptor) => interceptor is CookieManager);
    dio.interceptors.insert(0, CookieManager(_cookieJar));
  }

  static Dio _createDio() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(CookieManager(_cookieJar));

    // When the session expires, Grails redirects API calls to the
    // login page, so the response is HTML instead of JSON.
    // Treat that case as 401 so the services can show a clear message.
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final String contentType =
              response.headers.value('content-type') ?? '';

          final bool isApiCall =
          response.requestOptions.path.startsWith('/api/');

          if (isApiCall && contentType.contains('text/html')) {
            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: Response<dynamic>(
                  requestOptions: response.requestOptions,
                  statusCode: 401,
                ),
                type: DioExceptionType.badResponse,
              ),
            );
          }

          handler.next(response);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }

    return dio;
  }

  static Future<void> clearSession() async {
    await _cookieJar.deleteAll();
  }
}
