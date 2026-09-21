import 'package:dio/dio.dart';

import '../models/login_request.dart';
import '../models/user_session.dart';
import 'api_client.dart';
import 'notification_service.dart';

class AuthService {
  static UserSession? currentUser;

  Future<UserSession> login(LoginRequest request) async {
    try {
      await ApiClient.clearSession();

      final Response<dynamic> loginResponse = await ApiClient.dio.post(
        '/login/authenticate',
        data: request.toFormData(),
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status >= 200 && status < 400;
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

        throw const AuthException('Invalid email or password.');
      }

      final Response<dynamic> userResponse = await ApiClient.dio.get('/api/me');

      if (userResponse.data is! Map) {
        throw const AuthException('Invalid response from the server.');
      }

      final Map<String, dynamic> userJson = Map<String, dynamic>.from(
        userResponse.data as Map,
      );

      final UserSession user = UserSession.fromJson(userJson);

      currentUser = user;

      // Link this phone to the user, so the server can send pushes.
      await AppNotificationService.instance.syncTokenWithBackend();

      return user;
    } on AuthException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AuthException('Backend connection timed out.');
      }

      if (error.type == DioExceptionType.connectionError) {
        throw const AuthException(
          'Cannot connect to the backend. Make sure Grails is running.',
        );
      }

      final int? statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        throw const AuthException('Invalid email or password.');
      }

      throw AuthException(
        'Login failed. Server error: ${statusCode ?? 'unknown'}',
      );
    } catch (_) {
      throw const AuthException('An unexpected error occurred.');
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String dateOfBirth,
    required String drivingLicenseNumber,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      await ApiClient.clearSession();

      final Response<dynamic> response = await ApiClient.dio.post(
        '/signup',
        data: {
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'dateOfBirth': dateOfBirth.trim(),
          'drivingLicenseNumber': drivingLicenseNumber.trim(),
          'password': password,
          'confirmPassword': confirmPassword,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) {
            return status != null && status < 500;
          },
        ),
      );

      final String location = response.headers.value('location') ?? '';

      final bool success =
          (response.statusCode == 302 || response.statusCode == 303) &&
              location.contains('/login');

      if (!success) {
        throw const AuthException(
          'Registration failed. The email or licence number may already be used.',
        );
      }
    } on AuthException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const AuthException('Backend connection timed out.');
      }

      if (error.type == DioExceptionType.connectionError) {
        throw const AuthException(
          'Cannot connect to the backend. Make sure Grails is running.',
        );
      }

      throw const AuthException('Registration failed. Please try again.');
    } catch (_) {
      throw const AuthException('An unexpected error occurred.');
    }
  }

  /// Called by the splash screen.
  /// If the session saved on the phone is still valid on the server,
  /// the user goes straight in without typing the password again.
  Future<UserSession?> restoreSession() async {
    try {
      final Response<dynamic> response = await ApiClient.dio.get('/api/me');

      if (response.data is! Map) {
        return null;
      }

      final UserSession user = UserSession.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );

      currentUser = user;

      await AppNotificationService.instance.syncTokenWithBackend();

      return user;
    } catch (_) {
      // No saved session, an expired one, or no connection:
      // in every case the user simply logs in normally.
      return null;
    }
  }

  Future<void> logout() async {
    // Must happen while the session is still valid.
    await AppNotificationService.instance.removeTokenFromBackend();

    try {
      await ApiClient.dio.post('/logout');
    } catch (_) {
      // Clear the local session even when the backend is unavailable.
    } finally {
      currentUser = null;
      await ApiClient.clearSession();
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
