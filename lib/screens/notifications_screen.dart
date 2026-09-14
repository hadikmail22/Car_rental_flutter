import 'package:flutter/material.dart';

import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../services/rental_service.dart';
import '../theme/app_theme.dart';
import 'rental_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _notificationIcon(String type) {
    switch (type.toUpperCase()) {
      case 'PICKUP':
        return Icons.key_outlined;

      case 'RETURN':
        return Icons.assignment_return_outlined;

      case 'CONFIRMED':
        return Icons.check_circle_outline;

      case 'CANCELLED':
        return Icons.cancel_outlined;

      case 'COMPLETED':
        return Icons.task_alt;

      default:
        return Icons.notifications_outlined;
    }
  }

  Color _notificationColor(String type) {
    switch (type.toUpperCase()) {
      case 'PICKUP':
        return Colors.blue;

      case 'RETURN':
        return Colors.orange;

      case 'CONFIRMED':
        return Colors.green;

      case 'CANCELLED':
        return Colors.red;

      case 'COMPLETED':
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

    return '${date.year}-$month-$day  '
        '$hour:$minute';
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    AppNotificationService.instance.markAsRead(notification.id);

    if (notification.rentalId == null) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final rental = await RentalService().getRentalById(
        notification.rentalId!,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RentalDetailsScreen(rental: rental),
        ),
      );
    } on RentalServiceException catch (error) {
      if (context.mounted) {
        Navigator.pop(context);
      }

      messenger.showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context);
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Unable to open rental details.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppNotificationService service = AppNotificationService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Notifications '
              '(${service.unreadCount})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                onPressed: service.unreadCount == 0
                    ? null
                    : service.markAllAsRead,
                child: const Text('Read all'),
              ),
            ],
          ),
          body: _buildBody(context, service),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppNotificationService service) {
    if (!service.configured) {
      return const _NotificationMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Firebase unavailable',
        message: 'Unable to connect to Firebase notifications.',
      );
    }

    if (service.notifications.isEmpty) {
      return const _NotificationMessage(
        icon: Icons.notifications_none,
        title: 'No notifications',
        message: 'New rental notifications will appear here.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: service.notifications.length,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 12);
      },
      itemBuilder: (context, index) {
        final AppNotification notification = service.notifications[index];

        final Color notificationColor = _notificationColor(notification.type);

        return Card(
          color: notification.isRead
              ? Colors.white
              : AppTheme.primaryYellow.withValues(alpha: 0.16),
          child: ListTile(
            onTap: () {
              _openNotification(context, notification);
            },
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: notificationColor.withValues(alpha: 0.12),
              child: Icon(
                _notificationIcon(notification.type),
                color: notificationColor,
              ),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.w600
                    : FontWeight.bold,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                '${notification.message}\n'
                '${_formatDate(notification.createdAt)}',
              ),
            ),
            isThreeLine: true,
            trailing: notification.isRead
                ? null
                : const Icon(
                    Icons.circle,
                    size: 10,
                    color: AppTheme.primaryBlue,
                  ),
          ),
        );
      },
    );
  }
}

class _NotificationMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _NotificationMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 70, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
