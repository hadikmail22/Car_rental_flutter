import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/user_session.dart';
import 'api_client.dart';

class AuthService {
  Future<UserSession> login(LoginRequest request) async {
    try {

      await ApiClient.clearSession();

      final Response<dynamic> loginResponse =
      await ApiClient.dio.post(
        '/login/authenticate',
        data: request.toFormData(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null &&
                status >= 200 &&
                status < 400;
          },
        ),
      );

      final String redirectLocation =
          loginResponse.headers.value('location') ?? '';

      final bool loginFailed =
          redirectLocation.contains('authfail') ||
              redirectLocation.contains('login_error');

      if (loginFailed) {
        await ApiClient.clearSession();

        throw const AuthException(
          'Invalid email or password.',
        );
      }


      final Response<dynamic> userResponse =
      await ApiClient.dio.get('/api/me');

      if (userResponse.data is! Map) {
        throw const AuthException(
          'Invalid response from the server.',
        );
      }

      final Map<String, dynamic> userJson =
      Map<String, dynamic>.from(
        userResponse.data as Map,
      );

      return UserSession.fromJson(userJson);
    } on AuthException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AuthException(
          'Backend connection timed out.',
        );
      }

      if (error.type == DioExceptionType.connectionError) {
        throw const AuthException(
          'Cannot connect to the backend. Make sure Grails is running.',
        );
      }

      final int? statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        throw const AuthException(
          'Invalid email or password.',
        );
      }

      throw AuthException(
        'Login failed. Server error: ${statusCode ?? 'unknown'}',
      );
    } catch (_) {
      throw const AuthException(
        'An unexpected error occurred.',
      );
    }
  }
}

class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() {
    return message;
  }
}