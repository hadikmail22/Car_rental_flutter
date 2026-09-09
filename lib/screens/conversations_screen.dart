import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  final bool isAdmin;

  const ConversationsScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> conversations = isAdmin
        ? [
            {
              'rentalId': 1,
              'name': 'customer@cars.com',
              'car': 'Toyota Camry',
              'unread': 2,
            },
            {
              'rentalId': 2,
              'name': 'customer2@cars.com',
              'car': 'Toyota RAV4',
              'unread': 0,
            },
          ]
        : [
            {
              'rentalId': 1,
              'name': 'Car Rental Admin',
              'car': 'Toyota Camry',
              'unread': 1,
            },
          ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          final Map<String, dynamic> conversation = conversations[index];

          final int unread = conversation['unread'] as int;

          return ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            leading: const CircleAvatar(
              backgroundColor: AppTheme.primaryYellow,
              child: Icon(Icons.person_outline, color: AppTheme.darkColor),
            ),
            title: Text(
              conversation['name'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Rental #${conversation['rentalId']}'
              ' • ${conversation['car']}',
            ),
            trailing: unread > 0
                ? Badge(label: Text('$unread'))
                : const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    rentalId: conversation['rentalId'] as int,
                    otherUserName: conversation['name'] as String,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
