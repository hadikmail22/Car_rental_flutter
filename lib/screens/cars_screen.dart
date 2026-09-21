import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/cars_catalog.dart';
import '../widgets/notification_bell.dart';
import 'notifications_screen.dart';

class CarsScreen extends StatelessWidget {
  const CarsScreen({super.key});

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const NotificationsScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: const Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      AppTheme.defaultRadius,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.directions_car_filled_rounded,
                  color: AppTheme.primaryBlue,
                  size: 23,
                ),
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fleet',
                    style: TextStyle(
                      color: AppTheme.darkColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'EXPLORE VEHICLES',
                    style: TextStyle(
                      color: AppTheme.primaryBlueDark,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 14,
              top: 8,
              bottom: 8,
            ),
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                _openNotifications(context);
              },
              icon: const NotificationBell(),
            ),
          ),
        ],
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FleetHeader(),
          Expanded(
            child: CarsCatalog(),
          ),
        ],
      ),
    );
  }
}

class _FleetHeader extends StatelessWidget {
  const _FleetHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderSoft,
          ),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'AVAILABLE FLEET',
                style: TextStyle(
                  color: AppTheme.primaryBlueDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Divider(
                  color: AppTheme.primaryYellowStrong,
                ),
              ),
            ],
          ),

          SizedBox(height: 12),

          Text(
            'Choose your next drive.',
            style: TextStyle(
              color: AppTheme.darkColor,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Search the fleet and compare vehicle details and daily rates.',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}