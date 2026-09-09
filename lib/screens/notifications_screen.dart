import 'package:flutter/material.dart';
import '../models/app_notification.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 1,
      title: 'Pickup Reminder',
      message: 'Your Toyota Camry pickup is scheduled for tomorrow.',
      type: 'PICKUP',
      createdAt: DateTime(2026, 9, 9, 9, 30),
      isRead: false,
    ),
    AppNotification(
      id: 2,
      title: 'Rental Confirmed',
      message: 'Your booking deposit was paid successfully.',
      type: 'CONFIRMED',
      createdAt: DateTime(2026, 9, 8, 14, 20),
      isRead: false,
    ),
    AppNotification(
      id: 3,
      title: 'Return Reminder',
      message: 'Your rental return date is today.',
      type: 'RETURN',
      createdAt: DateTime(2026, 9, 7, 8),
      isRead: true,
    ),
  ];

  int get _unreadCount {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  void _markAsRead(int index) {
    if (_notifications[index].isRead) {
      return;
    }

    setState(() {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int index = 0; index < _notifications.length; index++) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'PICKUP':
        return Icons.key_outlined;

      case 'RETURN':
        return Icons.assignment_return_outlined;

      case 'CONFIRMED':
        return Icons.check_circle_outline;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'PICKUP':
        return Colors.blue;

      case 'RETURN':
        return Colors.orange;

      case 'CONFIRMED':
        return Colors.green;

      default:
        return AppTheme.primaryBlue;
    }
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    final String hour = date.hour.toString().padLeft(2, '0');

    final String minute = date.minute.toString().padLeft(2, '0');

    return '${date.year}-$month-$day  $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications ($_unreadCount)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _unreadCount == 0 ? null : _markAllAsRead,
            child: const Text('Read all'),
          ),
        ],
      ),

      body: _notifications.isEmpty
          ? const Center(child: Text('No notifications'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final AppNotification notification = _notifications[index];

                final Color color = _notificationColor(notification.type);

                return InkWell(
                  onTap: () {
                    _markAsRead(index);
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.white
                          : AppTheme.primaryYellow.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: notification.isRead
                            ? Colors.grey.shade300
                            : AppTheme.primaryYellow,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.12),
                          child: Icon(
                            _notificationIcon(notification.type),
                            color: color,
                          ),
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
                                      notification.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: notification.isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  if (!notification.isRead)
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              Text(
                                notification.message,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Text(
                                _formatDate(notification.createdAt),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
