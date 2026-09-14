import 'package:flutter/material.dart';

import '../models/user_session.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/logout_helper.dart';
import '../widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserSession? user = AuthService.currentUser;

    final String role = user?.isAdmin == true ? 'Admin' : 'Customer';

    final String displayName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : 'Car Rental User';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 52,
                backgroundColor: AppTheme.primaryYellow,
                child: Icon(Icons.person, size: 62, color: AppTheme.darkColor),
              ),

              const SizedBox(height: 18),

              Text(
                displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                user?.email ?? '',
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),

              const SizedBox(height: 30),

              _ProfileInfoTile(
                icon: Icons.email_outlined,
                title: 'Email',
                value: user?.email.isNotEmpty == true
                    ? user!.email
                    : 'Not available',
              ),

              _ProfileInfoTile(
                icon: Icons.security_outlined,
                title: 'Role',
                value: role,
              ),

              if (user?.phone?.isNotEmpty == true)
                _ProfileInfoTile(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  value: user!.phone!,
                ),

              if (user?.dateOfBirth?.isNotEmpty == true)
                _ProfileInfoTile(
                  icon: Icons.cake_outlined,
                  title: 'Date of Birth',
                  value: user!.dateOfBirth!,
                ),

              if (user?.drivingLicenseNumber?.isNotEmpty == true)
                _ProfileInfoTile(
                  icon: Icons.badge_outlined,
                  title: 'Driving License',
                  value: user!.drivingLicenseNumber!,
                ),

              const Spacer(),

              PrimaryButton(
                text: 'Logout',
                onPressed: () {
                  showLogoutDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
