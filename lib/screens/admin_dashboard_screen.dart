import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_session.dart';
import '../providers/car_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/rental_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/logout_helper.dart';
import '../widgets/notification_bell.dart';
import 'admin_cars_screen.dart';
import 'admin_rentals_screen.dart';
import 'conversations_screen.dart';
import 'notifications_screen.dart';
import 'pricing_rules_screen.dart';
import 'profile_screen.dart';

class AdminDashboardScreen
    extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() {
    return _AdminDashboardScreenState();
  }
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        _refreshDashboard();
      },
    );
  }

  Future<void> _refreshDashboard() async {
    await Future.wait<void>([
      context.read<CarsProvider>().loadCars(),
      context
          .read<RentalsProvider>()
          .loadRentals(),
      context
          .read<ChatProvider>()
          .loadConversations(),
    ]);
  }

  void _openScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return screen;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CarsProvider carsProvider =
    context.watch<CarsProvider>();

    final RentalsProvider rentalsProvider =
    context.watch<RentalsProvider>();

    final ChatProvider chatProvider =
    context.watch<ChatProvider>();

    final UserSession? user =
        AuthService.currentUser;

    final bool isLoading =
        carsProvider.isLoading ||
            rentalsProvider.isLoading ||
            chatProvider.isLoadingConversations;

    final String adminName =
    user?.fullName.trim().isNotEmpty == true
        ? user!.fullName.trim()
        : 'Administrator';

    final String? errorMessage =
        carsProvider.errorMessage ??
            rentalsProvider.errorMessage ??
            chatProvider.conversationsError;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed:
            isLoading ? null : _refreshDashboard,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {
              _openScreen(
                const NotificationsScreen(),
              );
            },
            icon: const NotificationBell(),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 8,
            ),
            child: IconButton(
              tooltip: 'Log out',
              onPressed: () {
                showLogoutDialog(context);
              },
              icon: const Icon(
                Icons.logout_rounded,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _refreshDashboard,
        child: ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            32,
          ),
          children: [
            _AdminHero(
              adminName: adminName,
              email: user?.email ?? '',
            ),
            if (isLoading) ...[
              const SizedBox(height: 18),
              const LinearProgressIndicator(
                minHeight: 3,
              ),
            ],
            if (errorMessage != null) ...[
              const SizedBox(height: 18),
              _DashboardError(
                message: errorMessage,
                onRetry: _refreshDashboard,
              ),
            ],
            const SizedBox(height: 26),
            const _SectionHeading(
              eyebrow: 'LIVE OVERVIEW',
              title: 'Business snapshot',
              description:
              'Current data from your rental system.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'TOTAL CARS',
                    value:
                    '${carsProvider.totalCars}',
                    icon: Icons
                        .directions_car_filled_rounded,
                    foreground:
                    AppTheme.primaryBlueDark,
                    background:
                    AppTheme.primaryBlueSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'RENTALS',
                    value:
                    '${rentalsProvider.totalRentals}',
                    icon:
                    Icons.receipt_long_rounded,
                    foreground:
                    AppTheme.successColor,
                    background:
                    AppTheme.successSoft,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _WideStatCard(
              title: 'UNREAD MESSAGES',
              value:
              '${chatProvider.totalUnreadMessages}',
              description: chatProvider
                  .totalUnreadMessages ==
                  0
                  ? 'All customer conversations are up to date.'
                  : 'Customer messages are waiting for your response.',
              icon: Icons
                  .mark_chat_unread_outlined,
              onTap: () {
                _openScreen(
                  const ConversationsScreen(
                    isAdmin: true,
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            const _SectionHeading(
              eyebrow: 'ADMIN TOOLS',
              title: 'Management',
              description:
              'Choose an area to manage.',
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (
                  BuildContext context,
                  BoxConstraints constraints,
                  ) {
                final int columns =
                constraints.maxWidth >= 700
                    ? 3
                    : 2;

                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio:
                  columns == 3 ? 1.35 : 1.08,
                  children: [
                    _ActionCard(
                      number: '01',
                      title: 'Cars',
                      description:
                      'Manage the fleet',
                      icon: Icons
                          .directions_car_outlined,
                      onTap: () {
                        _openScreen(
                          const AdminCarsScreen(),
                        );
                      },
                    ),
                    _ActionCard(
                      number: '02',
                      title: 'Rentals',
                      description:
                      'Manage bookings',
                      icon: Icons
                          .calendar_month_outlined,
                      onTap: () {
                        _openScreen(
                          const AdminRentalsScreen(),
                        );
                      },
                    ),
                    _ActionCard(
                      number: '03',
                      title: 'Pricing',
                      description:
                      'Dynamic price rules',
                      icon: Icons
                          .price_change_outlined,
                      onTap: () {
                        _openScreen(
                          const PricingRulesScreen(),
                        );
                      },
                    ),
                    _ActionCard(
                      number: '04',
                      title: 'Messages',
                      description:
                      'Customer support',
                      icon: Icons
                          .chat_bubble_outline_rounded,
                      badgeCount: chatProvider
                          .totalUnreadMessages,
                      onTap: () {
                        _openScreen(
                          const ConversationsScreen(
                            isAdmin: true,
                          ),
                        );
                      },
                    ),
                    _ActionCard(
                      number: '05',
                      title: 'Alerts',
                      description:
                      'Rental updates',
                      icon: Icons
                          .notifications_outlined,
                      onTap: () {
                        _openScreen(
                          const NotificationsScreen(),
                        );
                      },
                    ),
                    _ActionCard(
                      number: '06',
                      title: 'Profile',
                      description:
                      'Account details',
                      icon: Icons
                          .person_outline_rounded,
                      onTap: () {
                        _openScreen(
                          const ProfileScreen(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHero extends StatelessWidget {
  final String adminName;
  final String email;

  const _AdminHero({
    required this.adminName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.darkColor,
        borderRadius: BorderRadius.circular(
          AppTheme.largeRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24171717),
            offset: Offset(6, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            bottom: -28,
            child: Icon(
              Icons
                  .admin_panel_settings_outlined,
              color: Colors.white.withValues(
                alpha: 0.06,
              ),
              size: 130,
            ),
          ),
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius:
                  BorderRadius.circular(
                    AppTheme.smallRadius,
                  ),
                ),
                child: const Text(
                  'ADMIN CONTROL',
                  style: TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome,\n$adminName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: -0.7,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 9),
                Text(
                  email,
                  style: const TextStyle(
                    color: Color(0xFFB7B7B7),
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const Row(
                children: [
                  Icon(
                    Icons
                        .verified_user_outlined,
                    color: AppTheme
                        .primaryYellow,
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Manage cars, rentals and customer activity.',
                    style: TextStyle(
                      color:
                      Color(0xFFD0D0D0),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading
    extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String description;

  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style:
          Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style:
          Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 3),
        Text(
          description,
          style:
          Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color foreground;
  final Color background;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
        border: Border.all(
          color: AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(
                AppTheme.smallRadius,
              ),
            ),
            child: Icon(
              icon,
              color: foreground,
              size: 23,
            ),
          ),
          const SizedBox(height: 17),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.darkColor,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.mutedColor,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _WideStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _WideStatCard({
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color:
                  AppTheme.primaryYellowSoft,
                  borderRadius:
                  BorderRadius.circular(
                    AppTheme.smallRadius,
                  ),
                ),
                child: Icon(
                  icon,
                  color:
                  AppTheme.primaryBlueDark,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                        AppTheme.mutedColor,
                        fontSize: 9,
                        fontWeight:
                        FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: const TextStyle(
                  color:
                  AppTheme.primaryBlueDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  const _ActionCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 43,
                    height: 43,
                    decoration: BoxDecoration(
                      color: AppTheme
                          .primaryYellowSoft,
                      borderRadius:
                      BorderRadius.circular(
                        AppTheme.smallRadius,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppTheme
                          .primaryBlueDark,
                      size: 23,
                    ),
                  ),
                  const Spacer(),
                  if (badgeCount > 0)
                    Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration:
                      const BoxDecoration(
                        color:
                        AppTheme.errorColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        badgeCount > 99
                            ? '99+'
                            : '$badgeCount',
                        style:
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    Text(
                      number,
                      style: const TextStyle(
                        color:
                        AppTheme.borderColor,
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.darkColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.mutedColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardError
    extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        11,
        8,
        11,
      ),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius: BorderRadius.circular(
          AppTheme.smallRadius,
        ),
        border: Border.all(
          color: AppTheme.errorColor
              .withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Retry',
            onPressed: onRetry,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.errorDark,
            ),
          ),
        ],
      ),
    );
  }
}