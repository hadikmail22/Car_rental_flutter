import 'package:flutter/material.dart';
import '../models/rental.dart';
import '../theme/app_theme.dart';
import 'rental_details_screen.dart';

class MyRentalsScreen extends StatelessWidget {
  const MyRentalsScreen({super.key});

  static final List<Rental> rentals = [
    Rental(
      id: 1,
      customerEmail: 'customer@cars.com',
      carName: 'Toyota Camry',
      startDate: DateTime(2026, 9, 10),
      endDate: DateTime(2026, 9, 13),
      totalPrice: 171,
      bookingDeposit: 50,
      depositPaid: false,
      securityDeposit: 200,
      damageCost: 0,
      status: 'PENDING',
    ),
    Rental(
      id: 2,
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

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PICKED_UP':
        return Colors.purple;
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Rentals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: rentals.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final Rental rental = rentals[index];
          final Color statusColor = _statusColor(rental.status);

          return InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RentalDetailsScreen(rental: rental),
                ),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.car_rental, size: 38),
                  ),

                  const SizedBox(width: 14),

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

                        const SizedBox(height: 5),

                        Text(
                          '${_formatDate(rental.startDate)}'
                          ' → '
                          '${_formatDate(rental.endDate)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '\$${rental.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Column(
                    children: [
                      Text(
                        rental.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
