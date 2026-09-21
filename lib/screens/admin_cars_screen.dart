import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/car_provider.dart';
import '../widgets/cars_catalog.dart';
import 'car_form_screen.dart';

class AdminCarsScreen extends StatelessWidget {
  const AdminCarsScreen({super.key});

  Future<void> _openAddCar(BuildContext context) async {
    final bool? created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const CarFormScreen(),
      ),
    );

    if (created == true && context.mounted) {
      await context.read<CarsProvider>().refreshCars();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Cars',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: const CarsCatalog(isAdmin: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddCar(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Car'),
      ),
    );
  }
}
