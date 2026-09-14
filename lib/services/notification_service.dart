import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../models/app_notification.dart';
import '../screens/rental_details_screen.dart';
import 'rental_service.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class AppNotificationService extends ChangeNotifier {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  final List<AppNotification> _notifications = [];

  bool _configured = false;
  String? _fcmToken;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((notification) {
    return !notification.isRead;
  }).length;

  bool get configured => _configured;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);

      if (kDebugMode) {
        debugPrint(
          'Notification permission: '
          '${settings.authorizationStatus}',
        );
      }

      _fcmToken = await FirebaseMessaging.instance.getToken();

      if (kDebugMode) {
        debugPrint('FCM TOKEN: ${_fcmToken ?? 'Unavailable'}');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;

        if (kDebugMode) {
          debugPrint('REFRESHED FCM TOKEN: $newToken');
        }

        notifyListeners();
      });

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

      final RemoteMessage? initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();

      if (initialMessage != null) {
        _addNotification(initialMessage);
      }

      _configured = true;
      notifyListeners();
    } catch (error, stackTrace) {
      _configured = false;

      if (kDebugMode) {
        debugPrint(
          'Firebase initialization failed: '
          '$error',
        );

        debugPrintStack(stackTrace: stackTrace);
      }

      notifyListeners();
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final AppNotification notification = _addNotification(message);

    final ScaffoldMessengerState? messenger =
        appScaffoldMessengerKey.currentState;

    if (messenger == null) {
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${notification.title}\n'
            '${notification.message}',
          ),
          duration: const Duration(seconds: 6),
          action: notification.rentalId == null
              ? null
              : SnackBarAction(
                  label: 'VIEW',
                  onPressed: () {
                    _openRental(notification.rentalId!);
                  },
                ),
        ),
      );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final AppNotification notification = _addNotification(message);

    markAsRead(notification.id);

    if (notification.rentalId != null) {
      await _openRental(notification.rentalId!);
    }
  }

  AppNotification _addNotification(RemoteMessage remoteMessage) {
    final RemoteNotification? remoteNotification = remoteMessage.notification;

    final int? rentalId = int.tryParse(
      remoteMessage.data['rentalId']?.toString() ?? '',
    );

    final String title =
        remoteNotification?.title ??
        remoteMessage.data['title']?.toString() ??
        'Car Rental';

    final String message =
        remoteNotification?.body ??
        remoteMessage.data['body']?.toString() ??
        'You have a new notification.';

    final AppNotification notification = AppNotification(
      id:
          remoteMessage.messageId?.hashCode ??
          DateTime.now().microsecondsSinceEpoch,
      title: title,
      message: message,
      type: remoteMessage.data['type']?.toString() ?? 'GENERAL',
      createdAt: remoteMessage.sentTime ?? DateTime.now(),
      isRead: false,
      rentalId: rentalId,
    );

    _notifications.removeWhere((existingNotification) {
      return existingNotification.id == notification.id;
    });

    _notifications.insert(0, notification);

    notifyListeners();

    return notification;
  }

  Future<void> _openRental(int rentalId) async {
    try {
      final rental = await RentalService().getRentalById(rentalId);

      final NavigatorState? navigator = appNavigatorKey.currentState;

      if (navigator == null) {
        return;
      }

      await navigator.push(
        MaterialPageRoute(
          builder: (context) => RentalDetailsScreen(rental: rental),
        ),
      );
    } on RentalServiceException catch (error) {
      appScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    }
  }

  void markAsRead(int id) {
    final int index = _notifications.indexWhere((notification) {
      return notification.id == id;
    });

    if (index == -1 || _notifications[index].isRead) {
      return;
    }

    _notifications[index] = _notifications[index].copyWith(isRead: true);

    notifyListeners();
  }

  void markAllAsRead() {
    bool changed = false;

    for (int index = 0; index < _notifications.length; index++) {
      if (!_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);

        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }
}
