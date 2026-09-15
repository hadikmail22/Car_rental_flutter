import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'cars_screen.dart';
import 'conversations_screen.dart';
import 'home_screen.dart';
import 'my_rentals_screen.dart';
import 'profile_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() {
    return _CustomerMainScreenState();
  }
}

class _CustomerMainScreenState
    extends State<CustomerMainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    CarsScreen(),
    MyRentalsScreen(),
    ConversationsScreen(
      isAdmin: false,
    ),
    ProfileScreen(),
  ];

  void _changeScreen(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderSoft,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x14171717),
              offset: Offset(0, -5),
              blurRadius: 16,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _changeScreen,
            destinations: const [
              NavigationDestination(
                tooltip: 'Home',
                icon: Icon(
                  Icons.home_outlined,
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                tooltip: 'Fleet',
                icon: Icon(
                  Icons.directions_car_outlined,
                ),
                selectedIcon: Icon(
                  Icons.directions_car_filled_rounded,
                ),
                label: 'Fleet',
              ),
              NavigationDestination(
                tooltip: 'Rentals',
                icon: Icon(
                  Icons.calendar_month_outlined,
                ),
                selectedIcon: Icon(
                  Icons.calendar_month_rounded,
                ),
                label: 'Rentals',
              ),
              NavigationDestination(
                tooltip: 'Messages',
                icon: Icon(
                  Icons.chat_bubble_outline_rounded,
                ),
                selectedIcon: Icon(
                  Icons.chat_bubble_rounded,
                ),
                label: 'Messages',
              ),
              NavigationDestination(
                tooltip: 'Profile',
                icon: Icon(
                  Icons.person_outline_rounded,
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}