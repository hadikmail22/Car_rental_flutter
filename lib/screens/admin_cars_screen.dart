import 'package:flutter/material.dart';

import '../widgets/cars_catalog.dart';

class AdminCarsScreen extends StatelessWidget {
  const AdminCarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Cars',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: const CarsCatalog(),
    );
  }
}