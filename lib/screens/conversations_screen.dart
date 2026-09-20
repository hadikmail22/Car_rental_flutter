import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_conversation.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  final bool isAdmin;

  const ConversationsScreen({
    super.key,
    required this.isAdmin,
  });

  @override
  State<ConversationsScreen> createState() {
    return _ConversationsScreenState();
  }
}

class _ConversationsScreenState
    extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        context
            .read<ChatProvider>()
            .loadConversations();
      },
    );
  }

  String _conversationName(
      ChatConversation conversation,
      ) {
    if (widget.isAdmin) {
      return conversation.customer.displayName;
    }

    return 'Car Rental Admin';
  }

  String _lastMessageText(
      ChatConversation conversation,
      ) {
    final message = conversation.lastMessage;

    if (message == null) {
      return 'No messages yet. Start the conversation.';
    }

    if (message.body.trim().isNotEmpty) {
      final String prefix =
      message.mine ? 'You: ' : '';

      return '$prefix${message.body.trim()}';
    }

    if (message.attachments.isNotEmpty) {
      return message.mine
          ? 'You sent a photo'
          : 'Sent a photo';
    }

    return 'New rental message';
  }

  String _formatTime(DateTime? date) {
    if (date == null) {
      return '';
    }

    final DateTime localDate =
    date.toLocal();

    final DateTime now = DateTime.now();

    final bool sameDay =
        now.year == localDate.year &&
            now.month == localDate.month &&
            now.day == localDate.day;

    if (sameDay) {
      final String hour =
      localDate.hour
          .toString()
          .padLeft(2, '0');

      final String minute =
      localDate.minute
          .toString()
          .padLeft(2, '0');

      return '$hour:$minute';
    }

    final String month =
    localDate.month
        .toString()
        .padLeft(2, '0');

    final String day =
    localDate.day
        .toString()
        .padLeft(2, '0');

    return '$day/$month';
  }

  bool _canArchive(
      ChatConversation conversation,
      ) {
    return conversation.rentalStatus ==
        'COMPLETED' ||
        conversation.rentalStatus ==
            'CANCELLED';
  }

  Future<void> _openConversation(
      ChatConversation conversation,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ChatScreen(
            rentalId: conversation.rentalId,
            otherUserName:
            _conversationName(
              conversation,
            ),
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await context
        .read<ChatProvider>()
        .loadConversations();
  }

  Future<void> _archiveConversation(
      ChatProvider provider,
      ChatConversation conversation,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (
          BuildContext dialogContext,
          ) {
        return AlertDialog(
          icon: const Icon(
            Icons.archive_outlined,
            color: AppTheme.primaryBlue,
            size: 43,
          ),
          title: const Text(
            'Remove conversation?',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'This conversation will be removed '
                'from your list. The rental record '
                'will not be deleted.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('KEEP'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('REMOVE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final bool success =
    await provider.archiveConversation(
      conversation.rentalId,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Conversation removed.'
              : provider.conversationsError ??
              'Unable to remove conversation.',
        ),
        backgroundColor: success
            ? AppTheme.successColor
            : AppTheme.errorColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatProvider provider =
    context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Column(
        children: [
          _MessagesHeader(
            conversationCount:
            provider.conversations.length,
            unreadCount:
            provider.totalUnreadMessages,
          ),
          Expanded(
            child: _buildBody(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ChatProvider provider) {
    if (provider.isLoadingConversations &&
        provider.conversations.isEmpty) {
      return const _MessagesLoadingState();
    }

    if (provider.conversationsError != null &&
        provider.conversations.isEmpty) {
      return _MessagesState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load messages',
        message:
        provider.conversationsError!,
        buttonText: 'TRY AGAIN',
        onPressed:
        provider.loadConversations,
      );
    }

    if (provider.conversations.isEmpty) {
      return _MessagesState(
        icon:
        Icons.chat_bubble_outline_rounded,
        title: 'No conversations yet',
        message: widget.isAdmin
            ? 'Customer conversations will appear '
            'after their rentals are confirmed.'
            : 'Your conversation with the rental '
            'team will appear after your booking '
            'is confirmed.',
        buttonText: 'REFRESH',
        onPressed:
        provider.loadConversations,
      );
    }

    return Column(
      children: [
        if (provider.isLoadingConversations)
          const LinearProgressIndicator(
            minHeight: 3,
          ),
        if (provider.conversationsError !=
            null)
          _MessagesErrorBanner(
            message:
            provider.conversationsError!,
            onClose:
            provider.clearConversationsError,
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh:
            provider.refreshConversations,
            child: ListView.separated(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding:
              const EdgeInsets.fromLTRB(
                16,
                18,
                16,
                30,
              ),
              itemCount:
              provider.conversations.length,
              separatorBuilder: (
                  BuildContext context,
                  int index,
                  ) {
                return const SizedBox(
                  height: 13,
                );
              },
              itemBuilder: (
                  BuildContext context,
                  int index,
                  ) {
                final ChatConversation
                conversation =
                provider
                    .conversations[index];

                return _ConversationCard(
                  conversation:
                  conversation,
                  displayName:
                  _conversationName(
                    conversation,
                  ),
                  lastMessage:
                  _lastMessageText(
                    conversation,
                  ),
                  formattedTime:
                  _formatTime(
                    conversation
                        .lastMessage
                        ?.createdAt,
                  ),
                  canArchive:
                  _canArchive(
                    conversation,
                  ),
                  isArchiving:
                  provider
                      .archivingRentalId ==
                      conversation.rentalId,
                  onTap: () {
                    _openConversation(
                      conversation,
                    );
                  },
                  onArchive: () {
                    _archiveConversation(
                      provider,
                      conversation,
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagesHeader
    extends StatelessWidget {
  final int conversationCount;
  final int unreadCount;

  const _MessagesHeader({
    required this.conversationCount,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        20,
        22,
        20,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderSoft,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color:
              AppTheme.primaryYellowSoft,
              borderRadius:
              BorderRadius.circular(
                AppTheme.defaultRadius,
              ),
              border: Border.all(
                color: AppTheme
                    .primaryYellowStrong,
              ),
            ),
            child: const Icon(
              Icons.forum_outlined,
              color:
              AppTheme.primaryBlueDark,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'RENTAL SUPPORT',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  'Your conversations',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount == 0
                      ? 'All your messages are up to date.'
                      : '$unreadCount unread message${unreadCount == 1 ? '' : 's'}.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            constraints:
            const BoxConstraints(
              minWidth: 48,
            ),
            padding:
            const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color:
              AppTheme.primaryBlueSoft,
              borderRadius:
              BorderRadius.circular(
                AppTheme.smallRadius,
              ),
              border: Border.all(
                color: AppTheme.primaryBlue,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$conversationCount',
                  style: const TextStyle(
                    color: AppTheme
                        .primaryBlueDark,
                    fontSize: 18,
                    fontWeight:
                    FontWeight.w700,
                  ),
                ),
                const Text(
                  'CHATS',
                  style: TextStyle(
                    color: AppTheme
                        .primaryBlueDark,
                    fontSize: 9,
                    fontWeight:
                    FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard
    extends StatelessWidget {
  final ChatConversation conversation;
  final String displayName;
  final String lastMessage;
  final String formattedTime;
  final bool canArchive;
  final bool isArchiving;
  final VoidCallback onTap;
  final VoidCallback onArchive;

  const _ConversationCard({
    required this.conversation,
    required this.displayName,
    required this.lastMessage,
    required this.formattedTime,
    required this.canArchive,
    required this.isArchiving,
    required this.onTap,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final bool unread =
        conversation.hasUnreadMessages;

    return Card(
      color: unread
          ? AppTheme.primaryYellowSoft
          : AppTheme.cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: unread
              ? AppTheme
              .primaryYellowStrong
              : AppTheme.borderColor,
        ),
        borderRadius:
        BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
      ),
      child: InkWell(
        onTap:
        isArchiving ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration:
                    BoxDecoration(
                      color: AppTheme
                          .primaryBlueSoft,
                      borderRadius:
                      BorderRadius.circular(
                        AppTheme
                            .defaultRadius,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color:
                      AppTheme.primaryBlue,
                      size: 27,
                    ),
                  ),
                  if (unread)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 19,
                        height: 19,
                        alignment:
                        Alignment.center,
                        decoration:
                        BoxDecoration(
                          color: AppTheme
                              .primaryBlue,
                          shape:
                          BoxShape.circle,
                          border: Border.all(
                            color: AppTheme
                                .cardColor,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          conversation
                              .unreadCount >
                              9
                              ? '9+'
                              : '${conversation.unreadCount}',
                          style:
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style: TextStyle(
                              color: AppTheme
                                  .darkColor,
                              fontSize: 15,
                              fontWeight: unread
                                  ? FontWeight
                                  .w700
                                  : FontWeight
                                  .w600,
                            ),
                          ),
                        ),
                        if (formattedTime
                            .isNotEmpty)
                          Text(
                            formattedTime,
                            style:
                            const TextStyle(
                              color: AppTheme
                                  .mutedColor,
                              fontSize: 10,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      conversation.car.fullName,
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme
                            .primaryBlueDark,
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastMessage,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unread
                            ? AppTheme.darkSoft
                            : AppTheme.mutedColor,
                        fontSize: 12,
                        fontWeight: unread
                            ? FontWeight.w600
                            : FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: [
                        _RentalBadge(
                          rentalId:
                          conversation
                              .rentalId,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        _StatusBadge(
                          status: conversation
                              .rentalStatus,
                        ),
                        const Spacer(),
                        if (conversation
                            .photoCount >
                            0) ...[
                          const Icon(
                            Icons
                                .photo_outlined,
                            color: AppTheme
                                .mutedColor,
                            size: 16,
                          ),
                          const SizedBox(
                            width: 4,
                          ),
                          Text(
                            '${conversation.photoCount}',
                            style:
                            const TextStyle(
                              color: AppTheme
                                  .mutedColor,
                              fontSize: 10,
                              fontWeight:
                              FontWeight
                                  .w600,
                            ),
                          ),
                        ],
                        if (canArchive) ...[
                          const SizedBox(
                            width: 5,
                          ),
                          isArchiving
                              ? const SizedBox(
                            width: 32,
                            height: 32,
                            child:
                            Padding(
                              padding:
                              EdgeInsets
                                  .all(
                                7,
                              ),
                              child:
                              CircularProgressIndicator(
                                strokeWidth:
                                2,
                              ),
                            ),
                          )
                              : IconButton(
                            tooltip:
                            'Remove conversation',
                            onPressed:
                            onArchive,
                            visualDensity:
                            VisualDensity
                                .compact,
                            icon:
                            const Icon(
                              Icons
                                  .archive_outlined,
                              color: AppTheme
                                  .primaryBlue,
                              size: 20,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RentalBadge extends StatelessWidget {
  final int rentalId;

  const _RentalBadge({
    required this.rentalId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius:
        BorderRadius.circular(
          AppTheme.smallRadius,
        ),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
      ),
      child: Text(
        'RENTAL #$rentalId',
        style: const TextStyle(
          color: AppTheme.mutedColor,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color foreground;
    Color background;

    switch (status) {
      case 'COMPLETED':
        foreground =
            AppTheme.successColor;
        background =
            AppTheme.successSoft;

      case 'CANCELLED':
        foreground =
            AppTheme.errorDark;
        background =
            AppTheme.errorSoft;

      case 'PICKED_UP':
        foreground =
        const Color(0xFF6F42C1);
        background =
        const Color(0xFFF0E8FC);

      default:
        foreground =
            AppTheme.primaryBlueDark;
        background =
            AppTheme.primaryBlueSoft;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius:
        BorderRadius.circular(
          AppTheme.smallRadius,
        ),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          color: foreground,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MessagesErrorBanner
    extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _MessagesErrorBanner({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin:
      const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        0,
      ),
      padding:
      const EdgeInsets.fromLTRB(
        14,
        10,
        6,
        10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius:
        BorderRadius.circular(
          AppTheme.smallRadius,
        ),
        border: Border.all(
          color: AppTheme.errorColor
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorDark,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorDark,
                fontSize: 12,
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              color: AppTheme.errorDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesLoadingState
    extends StatelessWidget {
  const _MessagesLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (
          BuildContext context,
          int index,
          ) {
        return const SizedBox(height: 13);
      },
      itemBuilder: (
          BuildContext context,
          int index,
          ) {
        return Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius:
            BorderRadius.circular(
              AppTheme.defaultRadius,
            ),
            border: Border.all(
              color: AppTheme.borderSoft,
            ),
          ),
          child: const Center(
            child:
            CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class _MessagesState
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _MessagesState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: () async {
        onPressed();
      },
      child: ListView(
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 75),
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme
                    .primaryBlueSoft,
                borderRadius:
                BorderRadius.circular(
                  AppTheme.largeRadius,
                ),
                border: Border.all(
                  color:
                  AppTheme.primaryBlue,
                ),
              ),
              child: Icon(
                icon,
                color:
                AppTheme.primaryBlue,
                size: 43,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }
}