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
        return Icons.key_rounded;

      case 'RETURN':
        return Icons.assignment_return_rounded;

      case 'CONFIRMED':
        return Icons.check_circle_outline_rounded;

      case 'CANCELLED':
        return Icons.cancel_outlined;

      case 'COMPLETED':
        return Icons.task_alt_rounded;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  _NotificationStyle _notificationStyle(
      String type,
      ) {
    switch (type.toUpperCase()) {
      case 'PICKUP':
        return const _NotificationStyle(
          foreground: AppTheme.primaryBlueDark,
          background: AppTheme.primaryBlueSoft,
        );

      case 'RETURN':
        return const _NotificationStyle(
          foreground: Color(0xFF806900),
          background: AppTheme.primaryYellowSoft,
        );

      case 'CONFIRMED':
      case 'COMPLETED':
        return const _NotificationStyle(
          foreground: AppTheme.successColor,
          background: AppTheme.successSoft,
        );

      case 'CANCELLED':
        return const _NotificationStyle(
          foreground: AppTheme.errorDark,
          background: AppTheme.errorSoft,
        );

      default:
        return const _NotificationStyle(
          foreground: AppTheme.primaryBlueDark,
          background: AppTheme.primaryBlueSoft,
        );
    }
  }

  String _formatDate(DateTime date) {
    final String month =
    date.month.toString().padLeft(2, '0');

    final String day =
    date.day.toString().padLeft(2, '0');

    final String hour =
    date.hour.toString().padLeft(2, '0');

    final String minute =
    date.minute.toString().padLeft(2, '0');

    return '${date.year}-$month-$day  $hour:$minute';
  }

  Future<void> _openNotification(
      BuildContext context,
      AppNotification notification,
      ) async {
    final AppNotificationService service =
        AppNotificationService.instance;

    service.markAsRead(notification.id);

    if (notification.rentalId == null) {
      return;
    }

    final ScaffoldMessengerState messenger =
    ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final rental =
      await RentalService().getRentalById(
        notification.rentalId!,
      );

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return RentalDetailsScreen(
              rental: rental,
            );
          },
        ),
      );
    } on RentalServiceException catch (error) {
      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open rental details.',
          ),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppNotificationService service =
        AppNotificationService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (
          BuildContext context,
          Widget? child,
          ) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 10,
                ),
                child: TextButton.icon(
                  onPressed: service.unreadCount == 0
                      ? null
                      : service.markAllAsRead,
                  icon: const Icon(
                    Icons.done_all_rounded,
                    size: 19,
                  ),
                  label: const Text('READ ALL'),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _NotificationsHeader(
                totalCount:
                service.notifications.length,
                unreadCount: service.unreadCount,
              ),
              Expanded(
                child: _buildBody(
                  context,
                  service,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context,
      AppNotificationService service,
      ) {
    if (!service.configured) {
      return const _NotificationMessage(
        icon: Icons.cloud_off_outlined,
        title: 'Firebase unavailable',
        message:
        'The app could not connect to Firebase notifications.',
      );
    }

    if (service.notifications.isEmpty) {
      return const _NotificationMessage(
        icon: Icons.notifications_none_rounded,
        title: 'No notifications yet',
        message:
        'Pickup reminders and rental updates will appear here.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        30,
      ),
      itemCount: service.notifications.length,
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
        final AppNotification notification =
        service.notifications[index];

        return _NotificationCard(
          notification: notification,
          icon: _notificationIcon(
            notification.type,
          ),
          style: _notificationStyle(
            notification.type,
          ),
          formattedDate: _formatDate(
            notification.createdAt,
          ),
          onTap: () {
            _openNotification(
              context,
              notification,
            );
          },
        );
      },
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  final int totalCount;
  final int unreadCount;

  const _NotificationsHeader({
    required this.totalCount,
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
              color: AppTheme.primaryYellowSoft,
              borderRadius: BorderRadius.circular(
                AppTheme.defaultRadius,
              ),
              border: Border.all(
                color:
                AppTheme.primaryYellowStrong,
              ),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppTheme.primaryBlueDark,
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
                  'RENTAL UPDATES',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  'Stay up to date',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  unreadCount == 0
                      ? 'You have no unread notifications.'
                      : '$unreadCount notification${unreadCount == 1 ? '' : 's'} waiting for you.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(
              minWidth: 50,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: unreadCount == 0
                  ? AppTheme.backgroundColor
                  : AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(
                AppTheme.smallRadius,
              ),
              border: Border.all(
                color: unreadCount == 0
                    ? AppTheme.borderColor
                    : AppTheme.primaryBlue,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '$totalCount',
                  style: TextStyle(
                    color: unreadCount == 0
                        ? AppTheme.darkSoft
                        : AppTheme.primaryBlueDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  unreadCount == 0
                      ? 'TOTAL'
                      : '$unreadCount NEW',
                  style: TextStyle(
                    color: unreadCount == 0
                        ? AppTheme.mutedColor
                        : AppTheme.primaryBlueDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;
  final IconData icon;
  final _NotificationStyle style;
  final String formattedDate;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.style,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? AppTheme.cardColor
          : AppTheme.primaryYellowSoft,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: notification.isRead
              ? AppTheme.borderColor
              : AppTheme.primaryYellowStrong,
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: style.background,
                  borderRadius:
                  BorderRadius.circular(
                    AppTheme.smallRadius,
                  ),
                ),
                child: Icon(
                  icon,
                  color: style.foreground,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight:
                              notification
                                  .isRead
                                  ? FontWeight
                                  .w600
                                  : FontWeight
                                  .w700,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            margin:
                            const EdgeInsets.only(
                              top: 5,
                              left: 8,
                            ),
                            decoration:
                            const BoxDecoration(
                              color:
                              AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      notification.message,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color:
                          AppTheme.mutedColor,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ),
                        if (notification.rentalId !=
                            null) ...[
                          Text(
                            'VIEW RENTAL',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                              color: AppTheme
                                  .primaryBlueDark,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons
                                .arrow_forward_rounded,
                            color:
                            AppTheme.primaryBlue,
                            size: 18,
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        Center(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(
                AppTheme.largeRadius,
              ),
              border: Border.all(
                color: AppTheme.primaryBlue,
              ),
            ),
            child: Icon(
              icon,
              size: 43,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style:
          Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 9),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),
      ],
    );
  }
}

class _NotificationStyle {
  final Color foreground;
  final Color background;

  const _NotificationStyle({
    required this.foreground,
    required this.background,
  });
}