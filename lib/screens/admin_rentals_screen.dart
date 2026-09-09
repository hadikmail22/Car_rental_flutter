import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../theme/app_theme.dart';

class AdminRentalsScreen extends StatefulWidget {
  const AdminRentalsScreen({super.key});

  @override
  State<AdminRentalsScreen> createState() => _AdminRentalsScreenState();
}

class _AdminRentalsScreenState extends State<AdminRentalsScreen> {
  final List<Rental> _rentals = [
    Rental(
      id: 1,
      customerEmail: 'customer@cars.com',
      carName: 'Toyota Camry',
      startDate: DateTime(2026, 9, 10),
      endDate: DateTime(2026, 9, 13),
      totalPrice: 171,
      bookingDeposit: 50,
      depositPaid: true,
      securityDeposit: 200,
      damageCost: 0,
      status: 'CONFIRMED',
    ),
    Rental(
      id: 2,
      customerEmail: 'customer2@cars.com',
      carName: 'Toyota RAV4',
      startDate: DateTime(2026, 9, 7),
      endDate: DateTime(2026, 9, 11),
      totalPrice: 308.75,
      bookingDeposit: 50,
      depositPaid: true,
      securityDeposit: 200,
      damageCost: 0,
      status: 'PICKED_UP',
    ),
    Rental(
      id: 3,
      customerEmail: 'customer@cars.com',
      carName: 'Hyundai Elantra',
      startDate: DateTime(2026, 8, 15),
      endDate: DateTime(2026, 8, 18),
      totalPrice: 152,
      bookingDeposit: 50,
      depositPaid: true,
      securityDeposit: 200,
      damageCost: 0,
      status: 'COMPLETED',
    ),
  ];

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.blue;

      case 'PICKED_UP':
        return Colors.orange;

      case 'COMPLETED':
        return Colors.green;

      case 'CANCELLED':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  String? _nextStatus(String currentStatus) {
    if (currentStatus == 'CONFIRMED') {
      return 'PICKED_UP';
    }

    if (currentStatus == 'PICKED_UP') {
      return 'COMPLETED';
    }

    return null;
  }

  String? _actionLabel(String currentStatus) {
    if (currentStatus == 'CONFIRMED') {
      return 'Mark Picked Up';
    }

    if (currentStatus == 'PICKED_UP') {
      return 'Complete Rental';
    }

    return null;
  }

  Future<void> _changeStatus(int index) async {
    final Rental rental = _rentals[index];
    final String? nextStatus = _nextStatus(rental.status);

    if (nextStatus == null) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Rental'),
          content: Text(
            'Change rental #${rental.id} from '
            '${rental.status} to $nextStatus?',
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
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _rentals[index] = rental.copyWith(status: nextStatus);
    });

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Rental changed to $nextStatus'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Rentals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rentals.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 14);
        },
        itemBuilder: (context, index) {
          final Rental rental = _rentals[index];
          final Color statusColor = _statusColor(rental.status);

          final String? actionLabel = _actionLabel(rental.status);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.car_rental, size: 32),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rental.carName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            rental.customerEmail,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        rental.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                Text(
                  '${_formatDate(rental.startDate)}'
                  ' → '
                  '${_formatDate(rental.endDate)}',
                ),

                const SizedBox(height: 8),

                Text(
                  'Total: '
                  '\$${rental.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  rental.depositPaid
                      ? 'Booking deposit paid'
                      : 'Booking deposit not paid',
                  style: TextStyle(
                    color: rental.depositPaid ? Colors.green : Colors.red,
                  ),
                ),

                if (actionLabel != null) ...[
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _changeStatus(index);
                      },
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
