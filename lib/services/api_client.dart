import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static final CookieJar _cookieJar = CookieJar();

  static final Dio dio = _createDio();

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
