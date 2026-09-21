import 'package:dio/dio.dart';

import '../models/server_notification.dart';
import 'api_client.dart';

class NotificationApiService {
  Future<List<ServerNotification>> getNotifications() async {
    try {
      final Response<dynamic> response = await ApiClient.dio.get(
        '/api/notifications',
      );

      if (response.data is! Map) {
        throw const NotificationApiException(
          'Invalid response from the server.',
        );
      }

      final Map<String, dynamic> body = Map<String, dynamic>.from(
        response.data as Map,
      );

      final List<dynamic> items = body['items'] is List
          ? body['items'] as List<dynamic>
          : <dynamic>[];

      return items
          .whereType<Map>()
          .map(
            (item) => ServerNotification.fromJson(
          Map<String, dynamic>.from(item),
        ),
      )
          .toList();
    } on NotificationApiException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError) {
        throw const NotificationApiException(
          'Cannot connect to the backend.',
        );
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const NotificationApiException(
          'The server took too long to respond.',
        );
      }

      final int? statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        throw const NotificationApiException(
          'Your session has expired. Please login again.',
        );
      }

      throw NotificationApiException(
        'Failed to load notifications. Server error: '
            '${statusCode ?? 'unknown'}',
      );
    } catch (_) {
      throw const NotificationApiException(
        'An unexpected error occurred while loading notifications.',
      );
    }
  }
}

class NotificationApiException implements Exception {
  final String message;

  const NotificationApiException(this.message);

  @override
  String toString() {
    return message;
  }
}
