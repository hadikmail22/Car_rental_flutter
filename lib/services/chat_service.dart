import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import 'api_client.dart';

class ChatService {
  Future<ChatConversationPage>
  getConversations() async {
    try {
      final Response<dynamic> response =
      await ApiClient.dio.get(
        '/api/chat/conversations',
      );

      return ChatConversationPage.fromJson(
        _requireJsonMap(response.data),
      );
    } on ChatServiceException {
      rethrow;
    } on DioException catch (error) {
      throw ChatServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage:
          'Failed to load conversations.',
        ),
      );
    } catch (_) {
      throw const ChatServiceException(
        'Invalid conversations response from the server.',
      );
    }
  }

  Future<ChatThread> getConversation(
      int rentalId,
      ) async {
    try {
      final Response<dynamic> response =
      await ApiClient.dio.get(
        '/api/chat/conversations/$rentalId',
      );

      return ChatThread.fromJson(
        _requireJsonMap(response.data),
      );
    } on ChatServiceException {
      rethrow;
    } on DioException catch (error) {
      throw ChatServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage:
          'Failed to load the conversation.',
        ),
      );
    } catch (_) {
      throw const ChatServiceException(
        'Invalid conversation response from the server.',
      );
    }
  }

  Future<ChatMessage> sendMessage({
    required int rentalId,
    required String body,
    String messageType = 'CHAT',
    List<XFile> photos = const <XFile>[],
  }) async {
    final String normalizedBody =
    body.trim();

    if (normalizedBody.isEmpty &&
        photos.isEmpty) {
      throw const ChatServiceException(
        'Write a message or select a photo.',
      );
    }

    if (normalizedBody.length > 2000) {
      throw const ChatServiceException(
        'The message cannot exceed 2000 characters.',
      );
    }

    if (photos.length > 8) {
      throw const ChatServiceException(
        'You can select a maximum of 8 photos.',
      );
    }

    try {
      final FormData formData = FormData();

      formData.fields.add(
        MapEntry<String, String>(
          'body',
          normalizedBody,
        ),
      );

      formData.fields.add(
        MapEntry<String, String>(
          'messageType',
          messageType,
        ),
      );

      for (final XFile photo in photos) {
        final List<int> bytes =
        await photo.readAsBytes();

        formData.files.add(
          MapEntry<String, MultipartFile>(
            'photos',
            MultipartFile.fromBytes(
              bytes,
              filename: photo.name,
            ),
          ),
        );
      }

      final Response<dynamic> response =
      await ApiClient.dio.post(
        '/api/chat/conversations/'
            '$rentalId/messages',
        data: formData,
      );

      final Map<String, dynamic> json =
      _requireJsonMap(response.data);

      final dynamic messageJson =
      json['message'];

      if (messageJson is! Map) {
        throw const ChatServiceException(
          'The server did not return the sent message.',
        );
      }

      return ChatMessage.fromJson(
        Map<String, dynamic>.from(
          messageJson,
        ),
      );
    } on ChatServiceException {
      rethrow;
    } on DioException catch (error) {
      throw ChatServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage:
          'Failed to send the message.',
        ),
      );
    } catch (_) {
      throw const ChatServiceException(
        'Unable to prepare or send the message.',
      );
    }
  }

  Future<void> archiveConversation(
      int rentalId,
      ) async {
    try {
      await ApiClient.dio.post(
        '/api/chat/conversations/'
            '$rentalId/archive',
      );
    } on DioException catch (error) {
      throw ChatServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage:
          'Failed to remove the conversation.',
        ),
      );
    } catch (_) {
      throw const ChatServiceException(
        'Unable to remove the conversation.',
      );
    }
  }

  String attachmentUrl(String path) {
    if (path.trim().isEmpty) {
      return '';
    }

    final Uri attachmentUri =
    Uri.parse(path);

    if (attachmentUri.hasScheme) {
      return attachmentUri.toString();
    }

    final String normalizedPath =
    path.startsWith('/')
        ? path
        : '/$path';

    return '${ApiClient.baseUrl}$normalizedPath';
  }

  Map<String, dynamic> _requireJsonMap(
      dynamic data,
      ) {
    if (data is Map) {
      return Map<String, dynamic>.from(
        data,
      );
    }

    throw const ChatServiceException(
      'Server response is not a JSON object.',
    );
  }

  String _getDioErrorMessage(
      DioException error, {
        required String defaultMessage,
      }) {
    if (error.type ==
        DioExceptionType.connectionTimeout ||
        error.type ==
            DioExceptionType.receiveTimeout ||
        error.type ==
            DioExceptionType.sendTimeout) {
      return 'The backend request timed out.';
    }

    if (error.type ==
        DioExceptionType.connectionError) {
      return 'Cannot connect to the backend. '
          'Make sure Grails is running.';
    }

    final int? statusCode =
        error.response?.statusCode;

    final dynamic responseData =
        error.response?.data;

    if (responseData is Map &&
        responseData['error'] != null) {
      return responseData['error'].toString();
    }

    if (statusCode == 401 ||
        statusCode == 403) {
      return 'Your session has expired. '
          'Please login again.';
    }

    if (statusCode == 404) {
      return 'The requested conversation was not found.';
    }

    return '$defaultMessage Server error: '
        '${statusCode ?? 'unknown'}';
  }
}

class ChatServiceException
    implements Exception {
  final String message;

  const ChatServiceException(
      this.message,
      );

  @override
  String toString() {
    return message;
  }
}