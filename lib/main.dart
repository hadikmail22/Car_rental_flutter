import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/car_provider.dart';
import 'providers/rental_provider.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => CarsProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => RentalsProvider(),
        ),
      ],
      child: const CarRentalApp(),
    ),
  );
}

class CarRentalApp extends StatelessWidget {
  const CarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Rental',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}