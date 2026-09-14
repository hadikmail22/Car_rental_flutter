import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient._();

  static final CookieJar _cookieJar = CookieJar();

  static final Dio dio = _createDio();

  static Dio _createDio() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: 'http://172.26.200.13:8080',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      CookieManager(_cookieJar),
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