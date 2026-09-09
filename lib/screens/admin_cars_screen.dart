import 'package:flutter/material.dart';
import '../models/car.dart';
import '../theme/app_theme.dart';
import 'car_details_screen.dart';
import 'car_form_screen.dart';
import 'cars_screen.dart';

class AdminCarsScreen extends StatefulWidget {
  const AdminCarsScreen({super.key});

  @override
  State<AdminCarsScreen> createState() => _AdminCarsScreenState();
}

class _AdminCarsScreenState extends State<AdminCarsScreen> {
  late List<Car> _cars;

  @override
  void initState() {
    super.initState();

    _cars = List<Car>.from(CarsScreen.cars);
  }

  Future<void> _addCar() async {
    final Car? newCar = await Navigator.push<Car>(
      context,
      MaterialPageRoute(builder: (context) => const CarFormScreen()),
    );

    if (newCar == null) {
      return;
    }

    setState(() {
      _cars.insert(0, newCar);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Car added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _editCar(int index) async {
    final Car currentCar = _cars[index];

    final Car? updatedCar = await Navigator.push<Car>(
      context,
      MaterialPageRoute(builder: (context) => CarFormScreen(car: currentCar)),
    );

    if (updatedCar == null) {
      return;
    }

    setState(() {
      _cars[index] = updatedCar;
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Car updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteCar(int index) async {
    final Car car = _cars[index];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Car'),
          content: Text(
            'Are you sure you want to delete '
            '${car.fullName}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _cars.removeAt(index);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Car deleted successfully')));
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Colors.green;

      case 'RENTED':
        return Colors.orange;

      case 'MAINTENANCE':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Cars',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: _cars.isEmpty
          ? const Center(child: Text('No cars found'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _cars.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                final Car car = _cars[index];
                final Color statusColor = _statusColor(car.status);

                return Card(
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CarDetailsScreen(car: car),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryYellow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.directions_car_filled,
                              size: 42,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  car.fullName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  '${car.year} • '
                                  '${car.plateNumber}',
                                  style: const TextStyle(color: Colors.grey),
                                ),

                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    Text(
                                      '\$${car.pricePerDay.toStringAsFixed(2)} / day',
                                      style: const TextStyle(
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Text(
                                      car.status,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editCar(index);
                              }

                              if (value == 'delete') {
                                _deleteCar(index);
                              }
                            },
                            itemBuilder: (context) {
                              return const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 10),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCar,
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: AppTheme.darkColor,
        icon: const Icon(Icons.add),
        label: const Text('Add Car'),
      ),
    );
  }
}
