import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../models/create_rental_request.dart';
import '../models/create_rental_response.dart';
import '../providers/rental_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class CreateRentalScreen extends StatefulWidget {
  final Car car;

  const CreateRentalScreen({
    super.key,
    required this.car,
  });

  @override
  State<CreateRentalScreen> createState() =>
      _CreateRentalScreenState();
}

class _CreateRentalScreenState
    extends State<CreateRentalScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    final String month =
    date.month.toString().padLeft(2, '0');

    final String day =
    date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  int get _rentalDays {
    if (_startDate == null || _endDate == null) {
      return 0;
    }

    return _endDate!
        .difference(_startDate!)
        .inDays +
        1;
  }

  double get _estimatedPrice {
    return _rentalDays * widget.car.pricePerDay;
  }

  Future<void> _selectStartDate() async {
    final DateTime today =
    DateUtils.dateOnly(DateTime.now());

    final DateTime? selectedDate =
    await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: DateTime(today.year + 2),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _startDate = selectedDate;

      if (_endDate != null &&
          _endDate!.isBefore(selectedDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final DateTime today =
    DateUtils.dateOnly(DateTime.now());

    final DateTime firstAllowedDate =
        _startDate ?? today;

    final DateTime? selectedDate =
    await showDatePicker(
      context: context,
      initialDate:
      _endDate ?? firstAllowedDate,
      firstDate: firstAllowedDate,
      lastDate: DateTime(today.year + 2),
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _endDate = selectedDate;
    });
  }

  Future<void> _confirmRental() async {
    if (!widget.car.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This car is not currently available.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select start and end dates.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Rental'),
          content: Text(
            'Rent ${widget.car.fullName} for '
                '$_rentalDays day(s)?\n\n'
                'Estimated base price: '
                '\$${_estimatedPrice.toStringAsFixed(2)}\n\n'
                'The backend will calculate the final '
                'price and applicable discounts.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final CreateRentalRequest request =
    CreateRentalRequest(
      carId: widget.car.id,
      startDate: _startDate!,
      endDate: _endDate!,
    );

    final RentalsProvider provider =
    context.read<RentalsProvider>();

    final CreateRentalResponse? response =
    await provider.createRental(request);

    if (!mounted) {
      return;
    }

    if (response == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Failed to create rental.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    await _showSuccessDialog(response);

    if (!mounted) {
      return;
    }

    Navigator.pop(context, true);
  }

  Future<void> _showSuccessDialog(
      CreateRentalResponse response,
      ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 55,
          ),
          title: const Text(
            'Rental Created',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultRow(
                title: 'Rental ID',
                value: '#${response.id}',
              ),
              const SizedBox(height: 12),
              _ResultRow(
                title: 'Final price',
                value:
                '\$${response.totalPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 12),
              _ResultRow(
                title: 'Status',
                value: response.status,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider =
    context.watch<RentalsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Rental'),
      ),
      body: IgnorePointer(
        ignoring: provider.isCreating,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.primaryYellow,
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.directions_car_filled,
                      size: 55,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.car.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${widget.car.pricePerDay.toStringAsFixed(2)} per day',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Rental period',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _DateField(
                label: 'Start Date',
                value: _formatDate(_startDate),
                icon:
                Icons.calendar_today_outlined,
                onTap: _selectStartDate,
              ),

              const SizedBox(height: 16),

              _DateField(
                label: 'End Date',
                value: _formatDate(_endDate),
                icon:
                Icons.event_available_outlined,
                onTap: _selectEndDate,
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    _PriceRow(
                      title: 'Rental days',
                      value: '$_rentalDays',
                    ),
                    const SizedBox(height: 12),
                    _PriceRow(
                      title: 'Price per day',
                      value:
                      '\$${widget.car.pricePerDay.toStringAsFixed(2)}',
                    ),
                    const Divider(height: 28),
                    _PriceRow(
                      title: 'Estimated base price',
                      value:
                      '\$${_estimatedPrice.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'The final price and discounts '
                          'are calculated by the backend.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              PrimaryButton(
                text: 'Confirm Rental',
                isLoading: provider.isCreating,
                onPressed: _confirmRental,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isTotal;

  const _PriceRow({
    required this.title,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTotal ? 17 : 15,
            fontWeight: isTotal
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 19 : 15,
            fontWeight: FontWeight.bold,
            color: isTotal
                ? AppTheme.primaryBlue
                : AppTheme.darkColor,
          ),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String title;
  final String value;

  const _ResultRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}