import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'customer_main_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.88,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();

    _decideStartScreen();
  }

  /*
   * While the logo animates, try the session saved on the phone.
   * Valid session  -> straight to the right home screen.
   * Anything else  -> the login screen, as before.
   */
  Future<void> _decideStartScreen() async {
    final List<dynamic> results = await Future.wait<dynamic>([
      AuthService().restoreSession(),
      // Keep the splash visible for at least a moment.
      Future<void>.delayed(const Duration(milliseconds: 1400)),
    ]);

    final UserSession? user = results.first as UserSession?;

    if (!mounted) {
      return;
    }

    if (user == null) {
      _openScreen(const LoginScreen());
      return;
    }

    _openScreen(
      user.isAdmin
          ? const AdminDashboardScreen()
          : const CustomerMainScreen(),
    );

    // If the app was opened by tapping a notification,
    // show that rental now that the user is in.
    AppNotificationService.instance.openPendingRental();
  }

  void _openScreen(Widget screen) {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            ) {
          return screen;
        },
        transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
            ) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _GridBackgroundPainter(),
            ),
          ),

          Positioned(
            top: -90,
            left: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryYellowSoft,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 24,
              ),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _TopLabel(),
                  ),

                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: const _SplashContent(),
                      ),
                    ),
                  ),

                  const _LoadingSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopLabel extends StatelessWidget {
  const _TopLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppTheme.primaryYellowStrong,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'PREMIUM MOBILITY',
          style: TextStyle(
            color: AppTheme.primaryBlueDark,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            border: Border.all(
              color: AppTheme.primaryYellowStrong,
            ),
            borderRadius: BorderRadius.circular(
              AppTheme.largeRadius,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F171717),
                offset: Offset(7, 7),
                blurRadius: 0,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            size: 62,
            color: AppTheme.primaryBlue,
          ),
        ),

        const SizedBox(height: 34),

        const Text(
          'Car Rental',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.darkColor,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          'PREMIUM MOBILITY',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.primaryBlueDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),

        const SizedBox(height: 30),

        Container(
          width: 54,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Drive luxury. Rent with confidence.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _LoadingSection extends StatelessWidget {
  const _LoadingSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            child: LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: AppTheme.borderSoft,
              color: AppTheme.primaryBlue,
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            'PREPARING YOUR DRIVE',
            style: TextStyle(
              color: AppTheme.mutedColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridBackgroundPainter extends CustomPainter {
  const _GridBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridPaint = Paint()
      ..color = AppTheme.borderSoft.withValues(alpha: 0.55)
      ..strokeWidth = 0.7;

    const double gridSize = 42;

    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }

    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _GridBackgroundPainter oldDelegate,
      ) {
    return false;
  }
}