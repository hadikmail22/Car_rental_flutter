import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

/*
 * Conversation list, messenger style.
 *
 * - Each row is one rental: the customer sees the car,
 *   the admin sees the customer.
 * - Active rentals first, past ones below.
 * - Unread rows are bold with a yellow count.
 * - Past conversations can be archived with a swipe.
 * - A search box filters by car, customer or rental number.
 */
class ConversationsScreen extends StatefulWidget {
  final bool isAdmin;

  const ConversationsScreen({
    super.key,
    required this.isAdmin,
  });

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const Set<String> _activeStatuses = {'CONFIRMED', 'PICKED_UP'};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ---------- Text helpers ----------

  String _title(ChatConversation conversation) {
    return widget.isAdmin
        ? conversation.customer.displayName
        : conversation.car.fullName;
  }

  String _subtitle(ChatConversation conversation) {
    return widget.isAdmin
        ? conversation.car.fullName
        : 'Car Rental Support';
  }

  String _initials(String text) {
    final List<String> parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }

    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _preview(ChatConversation conversation) {
    final ChatMessage? message = conversation.lastMessage;

    if (message == null) {
      return 'No messages yet';
    }

    final String prefix = message.mine ? 'You: ' : '';

    if (message.body.trim().isNotEmpty) {
      return '$prefix${message.body.trim()}';
    }

    if (message.attachments.isNotEmpty) {
      final int count = message.attachments.length;
      return '${prefix}Photo${count > 1 ? 's ($count)' : ''}';
    }

    return 'New message';
  }

  String _time(DateTime? date) {
    if (date == null) {
      return '';
    }

    final DateTime local = date.toLocal();
    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final DateTime day = DateUtils.dateOnly(local);
    final int daysAgo = today.difference(day).inDays;

    if (daysAgo == 0) {
      return '${local.hour.toString().padLeft(2, '0')}:'
          '${local.minute.toString().padLeft(2, '0')}';
    }

    if (daysAgo == 1) {
      return 'Yesterday';
    }

    if (daysAgo < 7) {
      const List<String> names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return names[local.weekday - 1];
    }

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }

  bool _matches(ChatConversation conversation) {
    if (_query.isEmpty) {
      return true;
    }

    final String text = [
      conversation.car.fullName,
      conversation.customer.displayName,
      conversation.customer.email,
      '#${conversation.rentalId}',
      '${conversation.rentalId}',
    ].join(' ').toLowerCase();

    return text.contains(_query);
  }

  // ---------- Actions ----------

  Future<void> _open(ChatConversation conversation) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ChatScreen(
            rentalId: conversation.rentalId,
            otherUserName: widget.isAdmin
                ? conversation.customer.displayName
                : 'Car Rental Admin',
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    await context.read<ChatProvider>().loadConversations();
  }

  Future<bool> _confirmArchive(ChatConversation conversation) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Archive conversation?'),
          content: const Text(
            'It will be removed from your list. '
                'The rental record is not deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('KEEP'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ARCHIVE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return false;
    }

    final ChatProvider provider = context.read<ChatProvider>();
    final bool success = await provider.archiveConversation(
      conversation.rentalId,
    );

    if (!mounted) {
      return success;
    }

    if (success) {
      HapticFeedback.lightImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Conversation archived.'
              : provider.conversationsError ?? 'Unable to archive.',
        ),
        backgroundColor: success ? null : AppTheme.errorColor,
      ),
    );

    return success;
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final ChatProvider provider = context.watch<ChatProvider>();

    final List<ChatConversation> visible =
    provider.conversations.where(_matches).toList();

    final List<ChatConversation> active = visible
        .where((c) => _activeStatuses.contains(c.rentalStatus))
        .toList();

    final List<ChatConversation> past = visible
        .where((c) => !_activeStatuses.contains(c.rentalStatus))
        .toList();

    final int unread = provider.totalUnreadMessages;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Messages'),
            if (unread > 0) ...[
              const SizedBox(width: 10),
              _CountBadge(count: unread),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: TextField(
              controller: _searchController,
              onChanged: (String value) {
                setState(() {
                  _query = value.trim().toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: widget.isAdmin
                    ? 'Search customer, car or rental #'
                    : 'Search car or rental #',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _query = '';
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: _buildList(provider, active, past),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
      ChatProvider provider,
      List<ChatConversation> active,
      List<ChatConversation> past,
      ) {
    if (provider.isLoadingConversations && provider.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.conversationsError != null &&
        provider.conversations.isEmpty) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load messages',
        message: provider.conversationsError!,
        actionLabel: 'TRY AGAIN',
        onAction: provider.loadConversations,
      );
    }

    if (provider.conversations.isEmpty) {
      return _EmptyState(
        icon: Icons.forum_outlined,
        title: 'No conversations yet',
        message: widget.isAdmin
            ? 'Chats open once a customer confirms a booking.'
            : 'A chat opens for each confirmed booking, '
            'so you can talk to us about pickup and return.',
      );
    }

    if (active.isEmpty && past.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        message: 'Nothing matches "$_query".',
      );
    }

    return RefreshIndicator(
      onRefresh: provider.loadConversations,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (active.isNotEmpty) ...[
            _SectionHeader(title: 'ACTIVE RENTALS', count: active.length),
            ...active.map(_buildRow),
          ],
          if (past.isNotEmpty) ...[
            _SectionHeader(
              title: 'PAST',
              count: past.length,
              hint: 'Swipe left to archive',
            ),
            ...past.map(_buildRow),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(ChatConversation conversation) {
    final bool archivable = !_activeStatuses.contains(conversation.rentalStatus);

    final Widget row = _ConversationRow(
      title: _title(conversation),
      subtitle: _subtitle(conversation),
      initials: _initials(_title(conversation)),
      preview: _preview(conversation),
      time: _time(conversation.lastMessage?.createdAt),
      rentalId: conversation.rentalId,
      status: conversation.rentalStatus,
      unreadCount: conversation.unreadCount,
      hasPhoto: conversation.lastMessage?.attachments.isNotEmpty ?? false,
      onTap: () => _open(conversation),
    );

    if (!archivable) {
      return row;
    }

    return Dismissible(
      key: ValueKey<int>(conversation.rentalId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmArchive(conversation),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.primaryBlue,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.archive_outlined, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ARCHIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
      child: row,
    );
  }
}

/*
 * ---------- Row ----------
 */
class _ConversationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String initials;
  final String preview;
  final String time;
  final int rentalId;
  final String status;
  final int unreadCount;
  final bool hasPhoto;
  final VoidCallback onTap;

  const _ConversationRow({
    required this.title,
    required this.subtitle,
    required this.initials,
    required this.preview,
    required this.time,
    required this.rentalId,
    required this.status,
    required this.unreadCount,
    required this.hasPhoto,
    required this.onTap,
  });

  bool get _unread => unreadCount > 0;

  @override
  Widget build(BuildContext context) {
    final _StatusLook look = _StatusLook.of(status);

    return Material(
      color: _unread ? AppTheme.primaryYellowSoft : AppTheme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppTheme.borderSoft),
            ),
          ),
          child: Row(
            children: [
              // Avatar with a small status dot, like "online" in messengers.
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                    _unread ? AppTheme.primaryYellow : AppTheme.primaryBlueSoft,
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: _unread
                            ? AppTheme.darkColor
                            : AppTheme.primaryBlueDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: look.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.darkColor,
                              fontSize: 15,
                              fontWeight:
                              _unread ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: TextStyle(
                            color: _unread
                                ? AppTheme.primaryBlueDark
                                : AppTheme.mutedColor,
                            fontSize: 12,
                            fontWeight:
                            _unread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$subtitle · #$rentalId · ${look.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.mutedColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (hasPhoto) ...[
                          const Icon(
                            Icons.photo_outlined,
                            size: 15,
                            color: AppTheme.mutedColor,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _unread
                                  ? AppTheme.darkColor
                                  : AppTheme.textColor,
                              fontSize: 13.5,
                              fontWeight:
                              _unread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (_unread) ...[
                          const SizedBox(width: 8),
                          _CountBadge(count: unreadCount),
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

class _StatusLook {
  final String label;
  final Color color;

  const _StatusLook(this.label, this.color);

  static _StatusLook of(String status) {
    switch (status) {
      case 'CONFIRMED':
        return const _StatusLook('Confirmed', AppTheme.primaryBlue);
      case 'PICKED_UP':
        return const _StatusLook('On the road', AppTheme.successColor);
      case 'COMPLETED':
        return const _StatusLook('Completed', AppTheme.mutedColor);
      case 'CANCELLED':
        return const _StatusLook('Cancelled', AppTheme.errorColor);
      default:
        return _StatusLook(status, AppTheme.mutedColor);
    }
  }
}

/*
 * ---------- Small pieces ----------
 */
class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryYellowStrong),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.darkColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final String? hint;

  const _SectionHeader({
    required this.title,
    required this.count,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Text(
            '$title · $count',
            style: const TextStyle(
              color: AppTheme.primaryBlueDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (hint != null)
            Text(
              hint!,
              style: const TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.darkColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
