import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/logout_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _displayName(UserSession? user) {
    if (user != null &&
        user.fullName.trim().isNotEmpty) {
      return user.fullName.trim();
    }

    return 'Car Rental User';
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
      return parts.first
          .substring(0, 1)
          .toUpperCase();
    }

    return '${parts.first.substring(0, 1)}'
        '${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final UserSession? user =
        AuthService.currentUser;

    final String displayName =
    _displayName(user);

    final String role =
    user?.isAdmin == true
        ? 'Administrator'
        : 'Customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            30,
          ),
          children: [
            _ProfileHeader(
              displayName: displayName,
              initials: _initials(displayName),
              email: user?.email ?? '',
              role: role,
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              eyebrow: 'PERSONAL DETAILS',
              title: 'Account information',
            ),
            const SizedBox(height: 12),
            _ProfileDetailsCard(
              user: user,
              role: role,
            ),
            const SizedBox(height: 18),
            const _AccountNotice(),
            const SizedBox(height: 24),
            _LogoutButton(
              onPressed: () {
                showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String initials;
  final String email;
  final String role;

  const _ProfileHeader({
    required this.displayName,
    required this.initials,
    required this.email,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius: BorderRadius.circular(
                    AppTheme.largeRadius,
                  ),
                  border: Border.all(
                    color:
                    AppTheme.primaryYellowStrong,
                    width: 2,
                  ),
                ),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 31,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Positioned(
                right: -5,
                bottom: -5,
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.darkColor,
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              email,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFB8B8B8),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue
                  .withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(
                AppTheme.smallRadius,
              ),
              border: Border.all(
                color: AppTheme.primaryBlue
                    .withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF8FC5FF),
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFD5E9FF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
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

class _SectionTitle extends StatelessWidget {
  final String eyebrow;
  final String title;

  const _SectionTitle({
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
          style: Theme.of(context)
              .textTheme
              .titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge,
        ),
      ],
    );
  }
}

class _ProfileDetailsCard extends StatelessWidget {
  final UserSession? user;
  final String role;

  const _ProfileDetailsCard({
    required this.user,
    required this.role,
  });

  bool _hasValue(String? value) {
    return value != null &&
        value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final List<_ProfileDetail> details = [
      _ProfileDetail(
        icon: Icons.email_outlined,
        label: 'EMAIL ADDRESS',
        value: _hasValue(user?.email)
            ? user!.email
            : 'Not available',
      ),
      _ProfileDetail(
        icon: Icons.security_outlined,
        label: 'ACCOUNT ROLE',
        value: role,
      ),
      if (_hasValue(user?.phone))
        _ProfileDetail(
          icon: Icons.phone_outlined,
          label: 'PHONE NUMBER',
          value: user!.phone!,
        ),
      if (_hasValue(user?.dateOfBirth))
        _ProfileDetail(
          icon: Icons.cake_outlined,
          label: 'DATE OF BIRTH',
          value: user!.dateOfBirth!,
        ),
      if (_hasValue(
        user?.drivingLicenseNumber,
      ))
        _ProfileDetail(
          icon: Icons.badge_outlined,
          label: 'DRIVING LICENSE',
          value:
          user!.drivingLicenseNumber!,
        ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 5,
        ),
        child: Column(
          children: List<Widget>.generate(
            details.length,
                (int index) {
              return Column(
                children: [
                  _ProfileInfoRow(
                    detail: details[index],
                  ),
                  if (index != details.length - 1)
                    const Divider(height: 1),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final _ProfileDetail detail;

  const _ProfileInfoRow({
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(
                AppTheme.smallRadius,
              ),
            ),
            child: Icon(
              detail.icon,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  detail.label,
                  style: const TextStyle(
                    color: AppTheme.mutedColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail.value,
                  style: const TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

class _AccountNotice extends StatelessWidget {
  const _AccountNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.primaryYellowSoft,
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
        border: Border.all(
          color: AppTheme.primaryYellowStrong,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.primaryBlueDark,
            size: 22,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Your account is protected',
                  style: TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your personal and rental information is securely connected to your account.',
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 12,
                    height: 1.5,
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

class _LogoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LogoutButton({
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.errorDark,
          side: const BorderSide(
            color: AppTheme.errorColor,
          ),
          backgroundColor: AppTheme.cardColor,
        ),
        icon: const Icon(
          Icons.logout_rounded,
        ),
        label: const Text('LOG OUT'),
      ),
    );
  }
}

class _ProfileDetail {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileDetail({
    required this.icon,
    required this.label,
    required this.value,
  });
}