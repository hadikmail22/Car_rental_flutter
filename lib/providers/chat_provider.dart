import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService =
  ChatService();

  final List<ChatConversation>
  _conversations = [];

  ChatThread? _currentThread;

  bool _isLoadingConversations = false;
  bool _isLoadingThread = false;
  bool _isSending = false;

  int? _archivingRentalId;

  String? _conversationsError;
  String? _threadError;
  String? _sendError;

  List<ChatConversation> get conversations {
    return List<ChatConversation>.unmodifiable(
      _conversations,
    );
  }

  ChatThread? get currentThread {
    return _currentThread;
  }

  List<ChatMessage> get messages {
    return List<ChatMessage>.unmodifiable(
      _currentThread?.messages ??
          <ChatMessage>[],
    );
  }

  bool get isLoadingConversations {
    return _isLoadingConversations;
  }

  bool get isLoadingThread {
    return _isLoadingThread;
  }

  bool get isSending {
    return _isSending;
  }

  int? get archivingRentalId {
    return _archivingRentalId;
  }

  String? get conversationsError {
    return _conversationsError;
  }

  String? get threadError {
    return _threadError;
  }

  String? get sendError {
    return _sendError;
  }

  bool get hasConversations {
    return _conversations.isNotEmpty;
  }

  bool get hasMessages {
    return messages.isNotEmpty;
  }

  int get totalUnreadMessages {
    return _conversations.fold<int>(
      0,
          (
          int total,
          ChatConversation conversation,
          ) {
        return total +
            conversation.unreadCount;
      },
    );
  }

  Future<void> loadConversations() async {
    if (_isLoadingConversations) {
      return;
    }

    _isLoadingConversations = true;
    _conversationsError = null;
    notifyListeners();

    try {
      final ChatConversationPage page =
      await _chatService
          .getConversations();

      _conversations
        ..clear()
        ..addAll(page.items);
    } on ChatServiceException catch (error) {
      _conversationsError = error.message;
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> refreshConversations() {
    return loadConversations();
  }

  Future<void> loadConversation(
      int rentalId,
      ) async {
    if (_isLoadingThread) {
      return;
    }

    _isLoadingThread = true;
    _threadError = null;
    _sendError = null;

    if (_currentThread?.rental.id !=
        rentalId) {
      _currentThread = null;
    }

    notifyListeners();

    try {
      _currentThread =
      await _chatService.getConversation(
        rentalId,
      );

      _markConversationReadLocally(
        rentalId,
      );
    } on ChatServiceException catch (error) {
      _threadError = error.message;
    } finally {
      _isLoadingThread = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentConversation()
  async {
    final int? rentalId =
        _currentThread?.rental.id;

    if (rentalId == null) {
      return;
    }

    await loadConversation(rentalId);
  }

  Future<bool> sendMessage({
    required int rentalId,
    required String body,
    String messageType = 'CHAT',
    List<XFile> photos = const <XFile>[],
  }) async {
    if (_isSending) {
      return false;
    }

    final String normalizedBody =
    body.trim();

    if (normalizedBody.isEmpty &&
        photos.isEmpty) {
      _sendError =
      'Write a message or select a photo.';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _sendError = null;
    notifyListeners();

    try {
      final ChatMessage sentMessage =
      await _chatService.sendMessage(
        rentalId: rentalId,
        body: normalizedBody,
        messageType: messageType,
        photos: photos,
      );

      final ChatThread? thread =
          _currentThread;

      if (thread != null &&
          thread.rental.id == rentalId) {
        _currentThread = ChatThread(
          rental: thread.rental,
          messages: <ChatMessage>[
            ...thread.messages,
            sentMessage,
          ],
        );
      }

      await _reloadConversationsSilently();

      return true;
    } on ChatServiceException catch (error) {
      _sendError = error.message;
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  Future<bool> archiveConversation(
      int rentalId,
      ) async {
    if (_archivingRentalId != null) {
      return false;
    }

    _archivingRentalId = rentalId;
    _conversationsError = null;
    notifyListeners();

    try {
      await _chatService
          .archiveConversation(rentalId);

      _conversations.removeWhere(
            (ChatConversation conversation) {
          return conversation.rentalId ==
              rentalId;
        },
      );

      if (_currentThread?.rental.id ==
          rentalId) {
        _currentThread = null;
      }

      return true;
    } on ChatServiceException catch (error) {
      _conversationsError = error.message;
      return false;
    } finally {
      _archivingRentalId = null;
      notifyListeners();
    }
  }

  void clearConversation() {
    _currentThread = null;
    _threadError = null;
    _sendError = null;
  }

  void clearConversationsError() {
    if (_conversationsError == null) {
      return;
    }

    _conversationsError = null;
    notifyListeners();
  }

  void clearSendError() {
    if (_sendError == null) {
      return;
    }

    _sendError = null;
    notifyListeners();
  }

  Future<void>
  _reloadConversationsSilently() async {
    try {
      final ChatConversationPage page =
      await _chatService
          .getConversations();

      _conversations
        ..clear()
        ..addAll(page.items);
    } on ChatServiceException {
      // Sending succeeded. A failed list
      // refresh should not hide that success.
    }
  }

  void _markConversationReadLocally(
      int rentalId,
      ) {
    final int index =
    _conversations.indexWhere(
          (ChatConversation conversation) {
        return conversation.rentalId ==
            rentalId;
      },
    );

    if (index == -1) {
      return;
    }

    final ChatConversation oldConversation =
    _conversations[index];

    _conversations[index] =
        ChatConversation(
          rentalId: oldConversation.rentalId,
          customer: oldConversation.customer,
          car: oldConversation.car,
          rentalStatus:
          oldConversation.rentalStatus,
          lastMessage:
          oldConversation.lastMessage,
          messageCount:
          oldConversation.messageCount,
          photoCount:
          oldConversation.photoCount,
          unreadCount: 0,
        );
  }
}