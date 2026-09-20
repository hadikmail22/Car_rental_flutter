import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/car_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/rental_provider.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/customer_main_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AppNotificationService.instance.initialize();

  runApp(const CarRentalApp());
}

class CarRentalApp extends StatelessWidget {
  const CarRentalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CarsProvider>(
          create: (BuildContext context) {
            return CarsProvider();
          },
        ),
        ChangeNotifierProvider<RentalsProvider>(
          create: (BuildContext context) {
            return RentalsProvider();
          },
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (BuildContext context) {
            return ChatProvider();
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: appScaffoldMessengerKey,
        debugShowCheckedModeBanner: false,
        title: 'Car Rental',
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (BuildContext context) {
            return const SplashScreen();
          },
          '/login': (BuildContext context) {
            return const LoginScreen();
          },
          '/register': (BuildContext context) {
            return const RegisterScreen();
          },
          '/customer': (BuildContext context) {
            return const CustomerMainScreen();
          },
          '/admin': (BuildContext context) {
            return const AdminDashboardScreen();
          },
        },
      ),
    );
  }
}
