import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import '../utils/logout_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 52,
              backgroundColor: AppTheme.primaryYellow,
              child: Icon(Icons.person, size: 62, color: AppTheme.darkColor),
            ),

            const SizedBox(height: 18),

            const Text(
              'Customer User',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            const Text(
              'customer@cars.com',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),

            const SizedBox(height: 30),

            const ListTile(
              leading: Icon(Icons.email_outlined, color: AppTheme.primaryBlue),
              title: Text('Email'),
              subtitle: Text('customer@cars.com'),
            ),

            const ListTile(
              leading: Icon(
                Icons.security_outlined,
                color: AppTheme.primaryBlue,
              ),
              title: Text('Role'),
              subtitle: Text('Customer'),
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
    );
  }
}
