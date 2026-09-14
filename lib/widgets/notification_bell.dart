import 'package:flutter/material.dart';

import '../services/notification_service.dart';

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context) {
    final AppNotificationService service = AppNotificationService.instance;

    return AnimatedBuilder(
      animation: service,
      builder: (context, child) {
        const Widget bell = Icon(Icons.notifications_outlined);

        if (service.unreadCount == 0) {
          return bell;
        }

        return Badge(
          label: Text(
            service.unreadCount > 99 ? '99+' : service.unreadCount.toString(),
          ),
          child: bell,
        );
      },
    );
  }
}
