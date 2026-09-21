import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/rental.dart';
import '../models/user_session.dart';
import '../providers/rental_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/logout_helper.dart';
import 'notifications_screen.dart';
import 'rental_history_screen.dart';

/*
 * Profile screen, shared by customers and admins.
 *
 * Top to bottom:
 *  1. A dark header with the avatar and role.
 *  2. For customers: trip stats taken from their real rentals.
 *  3. A driver card styled like a real licence.
 *  4. Quick links and contact details.
 *  5. Logout.
 */
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    // Stats need the customer's rentals. They may already be loaded
    // by the Rentals tab; if not, load them once here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final UserSession? user = AuthService.currentUser;

      if (user == null || user.isAdmin) {
        return;
      }

      final RentalsProvider provider = context.read<RentalsProvider>();

      if (provider.rentals.isEmpty && !provider.isLoading) {
        provider.loadRentals();
      }

      if (provider.historyRentals.isEmpty && !provider.isLoadingHistory) {
        provider.loadRentalHistory();
      }
    });
  }

  String _displayName(UserSession? user) {
    final String name = user?.fullName.trim() ?? '';
    return name.isNotEmpty ? name : 'Car Rental User';
  }

  String _initials(String name) {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'CR';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    HapticFeedback.selectionClick();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _open(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final UserSession? user = AuthService.currentUser;
    final bool isAdmin = user?.isAdmin == true;
    final String displayName = _displayName(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
        children: [
          _ProfileHeader(
            displayName: displayName,
            initials: _initials(displayName),
            email: user?.email ?? '',
            isAdmin: isAdmin,
          ),

          if (!isAdmin) ...[
            const SizedBox(height: 14),
            const _TripStats(),
          ],

          const SizedBox(height: 26),
          const _SectionLabel('DRIVER CARD'),
          const SizedBox(height: 10),
          _DriverCard(
            name: displayName,
            licence: user?.drivingLicenseNumber,
            dateOfBirth: user?.dateOfBirth,
            isAdmin: isAdmin,
          ),

          const SizedBox(height: 26),
          const _SectionLabel('SHORTCUTS'),
          const SizedBox(height: 10),
          _Panel(
            children: [
              if (!isAdmin)
                _ActionRow(
                  icon: Icons.history_rounded,
                  title: 'Rental history',
                  subtitle: 'Completed and cancelled trips',
                  onTap: () => _open(const RentalHistoryScreen()),
                ),
              _ActionRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Pickups, returns and messages',
                onTap: () => _open(const NotificationsScreen()),
              ),
            ],
          ),

          const SizedBox(height: 26),
          const _SectionLabel('CONTACT'),
          const SizedBox(height: 10),
          _Panel(
            children: [
              _InfoRow(
                icon: Icons.alternate_email_rounded,
                label: 'Email',
                value: user?.email ?? '-',
                onCopy: user?.email == null
                    ? null
                    : () => _copy('Email', user!.email),
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: (user?.phone?.isNotEmpty ?? false) ? user!.phone! : '-',
                onCopy: (user?.phone?.isNotEmpty ?? false)
                    ? () => _copy('Phone number', user!.phone!)
                    : null,
              ),
            ],
          ),

          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: () => showLogoutDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorDark,
              side: const BorderSide(color: AppTheme.errorColor),
              minimumSize: const Size.fromHeight(52),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('LOG OUT'),
          ),

          const SizedBox(height: 14),
          const Center(
            child: Text(
              'Car Rental · Mobile 1.0',
              style: TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
 * ---------- Header ----------
 */
class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String initials;
  final String email;
  final bool isAdmin;

  const _ProfileHeader({
    required this.displayName,
    required this.initials,
    required this.email,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      child: Container(
        color: AppTheme.darkColor,
        child: Stack(
          children: [
            // Road markings in the background, a quiet nod to driving.
            const Positioned.fill(
              child: CustomPaint(painter: _RoadStripesPainter()),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Row(
                children: [
                  // Avatar with a yellow ring.
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryYellow,
                          AppTheme.primaryYellowStrong,
                        ],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppTheme.darkSoft,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppTheme.primaryYellow,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RoleChip(isAdmin: isAdmin),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final bool isAdmin;

  const _RoleChip({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppTheme.primaryYellow
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(
          color: isAdmin
              ? AppTheme.primaryYellowStrong
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings_outlined : Icons.verified_outlined,
            size: 14,
            color: isAdmin ? AppTheme.darkColor : AppTheme.primaryYellow,
          ),
          const SizedBox(width: 6),
          Text(
            isAdmin ? 'ADMINISTRATOR' : 'VERIFIED DRIVER',
            style: TextStyle(
              color: isAdmin ? AppTheme.darkColor : Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadStripesPainter extends CustomPainter {
  const _RoadStripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.primaryYellow.withValues(alpha: 0.07)
      ..strokeWidth = 10;

    // Diagonal dashed lane marks on the right side.
    for (double offset = -40; offset < size.height + 60; offset += 34) {
      final double x = size.width - 70 + offset * 0.35;
      canvas.drawLine(
        Offset(x, offset),
        Offset(x + 10, offset + 18),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RoadStripesPainter oldDelegate) => false;
}

/*
 * ---------- Trip stats (customers) ----------
 * Numbers come from the rentals the provider already holds.
 */
class _TripStats extends StatelessWidget {
  const _TripStats();

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider = context.watch<RentalsProvider>();

    final List<Rental> history = provider.historyRentals;

    final int active = provider.rentals
        .where((Rental rental) =>
    rental.status == 'CONFIRMED' || rental.status == 'PICKED_UP')
        .length;

    final List<Rental> completed = history
        .where((Rental rental) => rental.status == 'COMPLETED')
        .toList();

    final double spent = completed.fold<double>(
      0,
          (double sum, Rental rental) => sum + rental.totalPrice,
    );

    final bool loading = provider.isLoading || provider.isLoadingHistory;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: loading ? '…' : '$active',
            label: 'ACTIVE',
            icon: Icons.directions_car_filled_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: loading ? '…' : '${completed.length}',
            label: 'TRIPS',
            icon: Icons.flag_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            value: loading ? '…' : '\$${spent.toStringAsFixed(0)}',
            label: 'SPENT',
            icon: Icons.payments_outlined,
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool highlight;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.primaryYellowSoft : AppTheme.cardColor,
        border: Border.all(
          color: highlight ? AppTheme.primaryYellowStrong : AppTheme.borderSoft,
        ),
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryBlue),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              value,
              key: ValueKey<String>(value),
              maxLines: 1,
              style: const TextStyle(
                color: AppTheme.darkColor,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

/*
 * ---------- Driver card ----------
 * Looks like a real driving licence: the details the rental
 * company actually checks before handing over a car.
 */
class _DriverCard extends StatelessWidget {
  final String name;
  final String? licence;
  final String? dateOfBirth;
  final bool isAdmin;

  const _DriverCard({
    required this.name,
    required this.licence,
    required this.dateOfBirth,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasLicence = licence != null && licence!.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Yellow band across the top, like on an ID card.
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            color: AppTheme.primaryYellow,
            child: Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 18,
                  color: AppTheme.darkColor,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'DRIVING LICENCE',
                    style: TextStyle(
                      color: AppTheme.darkColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.darkColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    hasLicence ? 'ON FILE' : (isAdmin ? 'STAFF' : 'MISSING'),
                    style: const TextStyle(
                      color: AppTheme.primaryYellow,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo placeholder.
                Container(
                  width: 58,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlueSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderSoft),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 32,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardField(label: 'NAME', value: name),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _CardField(
                              label: 'NUMBER',
                              value: hasLicence ? licence! : '-',
                              mono: true,
                            ),
                          ),
                          Expanded(
                            child: _CardField(
                              label: 'BORN',
                              value: (dateOfBirth?.isNotEmpty ?? false)
                                  ? dateOfBirth!
                                  : '-',
                              mono: true,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _CardField extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _CardField({
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.darkColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: mono ? 0.6 : 0,
          ),
        ),
      ],
    );
  }
}

/*
 * ---------- Lists ----------
 */
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primaryBlueDark,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.3,
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = [];

    for (int index = 0; index < children.length; index++) {
      if (index > 0) {
        rows.add(const Divider(height: 1, indent: 62));
      }
      rows.add(children[index]);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderSoft),
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        child: Row(
          children: [
            _IconBox(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.darkColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.mutedColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.mutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          _IconBox(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.mutedColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copy $label',
              onPressed: onCopy,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                side: BorderSide.none,
              ),
              icon: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppTheme.mutedColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryBlueSoft,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Icon(icon, size: 19, color: AppTheme.primaryBlue),
    );
  }
}
