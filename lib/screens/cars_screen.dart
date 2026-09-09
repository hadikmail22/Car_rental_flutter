import 'package:flutter/material.dart';
import '../models/car.dart';
import '../theme/app_theme.dart';
import 'car_details_screen.dart';

class CarsScreen extends StatelessWidget {
  const CarsScreen({super.key});

  static const List<Car> cars = [
    Car(
      id: 1,
      brand: 'Toyota',
      model: 'Camry',
      year: 2024,
      plateNumber: 'SED-CAM-24',
      pricePerDay: 45,
      status: 'AVAILABLE',
      category: 'Sedan',
    ),
    Car(
      id: 2,
      brand: 'Hyundai',
      model: 'Elantra',
      year: 2023,
      plateNumber: 'SED-ELA-23',
      pricePerDay: 40,
      status: 'RENTED',
      category: 'Sedan',
    ),
    Car(
      id: 3,
      brand: 'Toyota',
      model: 'RAV4',
      year: 2024,
      plateNumber: 'SUV-RAV-24',
      pricePerDay: 65,
      status: 'AVAILABLE',
      category: 'SUV',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cars',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cars.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          final Car car = cars[index];

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
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_car_filled,
                        size: 48,
                        color: AppTheme.darkColor,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            '${car.year} • ${car.category}',
                            style: const TextStyle(color: Colors.grey),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            '\$${car.pricePerDay.toStringAsFixed(2)} / day',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.arrow_forward_ios, size: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
