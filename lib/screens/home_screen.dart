import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/notification_bell.dart';
import 'cars_screen.dart';
import 'my_rentals_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCars(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const CarsScreen();
        },
      ),
    );
  }

  void _openRentals(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const MyRentalsScreen();
        },
      ),
    );
  }

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
        title: const _BrandTitle(),
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
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _HomeGridPainter(),
            ),
          ),
          RefreshIndicator(
            onRefresh: () async {
              await Future<void>.delayed(
                const Duration(milliseconds: 500),
              );
            },
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                32,
              ),
              children: [
                const _WelcomeSection(),

                const SizedBox(height: 22),

                _HeroCard(
                  onBrowseCars: () {
                    _openCars(context);
                  },
                ),

                const SizedBox(height: 26),

                const _SectionHeader(
                  eyebrow: 'QUICK ACCESS',
                  title: 'What would you like to do?',
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon:
                        Icons.directions_car_outlined,
                        title: 'Explore Fleet',
                        subtitle: 'Find your next car',
                        accentColor:
                        AppTheme.primaryYellow,
                        iconColor:
                        AppTheme.primaryBlue,
                        onTap: () {
                          _openCars(context);
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: _QuickActionCard(
                        icon:
                        Icons.calendar_month_outlined,
                        title: 'My Rentals',
                        subtitle: 'Track your bookings',
                        accentColor:
                        AppTheme.primaryBlueSoft,
                        iconColor:
                        AppTheme.primaryBlue,
                        onTap: () {
                          _openRentals(context);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                const _SectionHeader(
                  eyebrow: 'RENT WITH CONFIDENCE',
                  title: 'A simpler rental experience',
                ),

                const SizedBox(height: 14),

                const _BenefitCard(
                  number: '01',
                  icon: Icons.car_rental_rounded,
                  title: 'Premium fleet',
                  description:
                  'Browse available vehicles with clear daily rates.',
                ),

                const SizedBox(height: 11),

                const _BenefitCard(
                  number: '02',
                  icon: Icons.price_check_rounded,
                  title: 'Transparent pricing',
                  description:
                  'Review rental pricing before confirming your booking.',
                ),

                const SizedBox(height: 11),

                const _BenefitCard(
                  number: '03',
                  icon: Icons.support_agent_rounded,
                  title: 'Direct support',
                  description:
                  'Stay connected with the rental team through messages.',
                ),

                const SizedBox(height: 26),

                _FleetBanner(
                  onPressed: () {
                    _openCars(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            border: Border.all(
              color: AppTheme.primaryYellowStrong,
            ),
            borderRadius: BorderRadius.circular(
              AppTheme.defaultRadius,
            ),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: AppTheme.primaryBlue,
            size: 24,
          ),
        ),

        const SizedBox(width: 11),

        const Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Car Rental',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.darkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'PREMIUM MOBILITY',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.primaryBlueDark,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  const _WelcomeSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'CUSTOMER JOURNEY',
              style: TextStyle(
                color: AppTheme.primaryBlueDark,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),
            SizedBox(width: 11),
            Expanded(
              child: Divider(
                color: AppTheme.primaryYellowStrong,
              ),
            ),
          ],
        ),

        SizedBox(height: 14),

        Text(
          'Find your\nperfect car.',
          style: TextStyle(
            color: AppTheme.darkColor,
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.6,
          ),
        ),

        SizedBox(height: 11),

        Text(
          'Explore our fleet and reserve your next drive with confidence.',
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 13,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final VoidCallback onBrowseCars;

  const _HeroCard({
    required this.onBrowseCars,
  });

  static const String _imageUrl =
      'https://images.unsplash.com/photo-1503376780353-7e6692767b70'
      '?auto=format&fit=crop&w=1400&q=85';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.darkColor,
        border: Border.all(
          color: AppTheme.darkColor,
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.largeRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26171717),
            offset: Offset(7, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
                ) {
              return const ColoredBox(
                color: AppTheme.darkColor,
                child: Center(
                  child: Icon(
                    Icons.directions_car_filled_rounded,
                    color: AppTheme.primaryYellow,
                    size: 90,
                  ),
                ),
              );
            },
          ),

          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [
                  Color(0xF2171717),
                  Color(0xA6171717),
                  Color(0x11171717),
                ],
              ),
            ),
          ),

          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'FEATURED FLEET',
                  style: TextStyle(
                    color: AppTheme.primaryYellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.8,
                  ),
                ),

                const SizedBox(height: 7),

                const Text(
                  'Your next drive\nstarts here.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                    letterSpacing: -1,
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: 170,
                  child: ElevatedButton.icon(
                    onPressed: onBrowseCars,
                    icon: const Icon(
                      Icons.directions_car_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'EXPLORE CARS',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
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

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: const TextStyle(
            color: AppTheme.primaryBlueDark,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.darkColor,
            fontSize: 19,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(
        AppTheme.defaultRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 148,
          ),

          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.borderColor,
            ),
            borderRadius: BorderRadius.circular(
              AppTheme.defaultRadius,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10171717),
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(
                    AppTheme.smallRadius,
                  ),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 23,
                ),
              ),

              const Spacer(),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.darkColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.mutedColor,
                  fontSize: 10,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(
          color: AppTheme.borderColor,
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              borderRadius: BorderRadius.circular(
                AppTheme.smallRadius,
              ),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppTheme.darkColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 13),

          Container(
            width: 35,
            height: 35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(
                AppTheme.smallRadius,
              ),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryBlue,
              size: 19,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.mutedColor,
                    fontSize: 10,
                    height: 1.4,
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

class _FleetBanner extends StatelessWidget {
  final VoidCallback onPressed;

  const _FleetBanner({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellowSoft,
        border: Border.all(
          color: AppTheme.primaryYellowStrong,
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.largeRadius,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.key_rounded,
            color: AppTheme.primaryBlue,
            size: 30,
          ),

          const SizedBox(height: 13),

          const Text(
            'Ready to get moving?',
            style: TextStyle(
              color: AppTheme.darkColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Compare available vehicles and choose the right one for your journey.',
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 11,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
              ),
              label: const Text(
                'VIEW COMPLETE FLEET',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeGridPainter extends CustomPainter {
  const _HomeGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.borderSoft.withValues(
        alpha: 0.45,
      )
      ..strokeWidth = 0.7;

    const double gridSize = 44;

    for (
    double x = 0;
    x <= size.width;
    x += gridSize
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (
    double y = 0;
    y <= size.height;
    y += gridSize
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _HomeGridPainter oldDelegate,
      ) {
    return false;
  }
}