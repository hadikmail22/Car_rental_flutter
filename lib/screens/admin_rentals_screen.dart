import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rental.dart';
import '../providers/rental_provider.dart';
import '../theme/app_theme.dart';

class AdminRentalsScreen extends StatefulWidget {
  const AdminRentalsScreen({super.key});

  @override
  State<AdminRentalsScreen> createState() => _AdminRentalsScreenState();
}

class _AdminRentalsScreenState extends State<AdminRentalsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalsProvider>().loadRentals();
    });
  }

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

  Future<void> _updateRental(Rental rental) async {
    final RentalsProvider provider = context.read<RentalsProvider>();

    final bool isCompleting = rental.status == 'PICKED_UP';

    final TextEditingController damageController = TextEditingController(
      text: '0',
    );

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isCompleting ? 'Complete Rental' : 'Confirm Pickup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isCompleting
                    ? 'Complete rental #${rental.id} and return the car?'
                    : 'Mark rental #${rental.id} as picked up?',
              ),

              if (isCompleting) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: damageController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Damage cost',
                    prefixText: '\$ ',
                    helperText: 'Enter 0 if there is no damage.',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
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

    if (confirmed != true || !mounted) {
      damageController.dispose();
      return;
    }

    final double? damageCost = double.tryParse(damageController.text.trim());

    damageController.dispose();

    if (isCompleting && (damageCost == null || damageCost < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid damage cost.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    final bool success;

    if (isCompleting) {
      success = await provider.completeRental(
        rental.id,
        damageCost: damageCost ?? 0,
      );
    } else {
      success = await provider.pickupRental(rental.id);
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? isCompleting
                    ? 'Rental completed successfully.'
                    : 'Car pickup confirmed successfully.'
              : provider.errorMessage ?? 'Unable to update rental.',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider = context.watch<RentalsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Rentals '
          '(${provider.totalRentals})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(RentalsProvider provider) {
    if (provider.isLoading && provider.rentals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.rentals.isEmpty) {
      return _AdminRentalsError(
        message: provider.errorMessage!,
        onRetry: provider.loadRentals,
      );
    }

    if (provider.rentals.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.refreshRentals,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 180),
            Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey),
            SizedBox(height: 16),
            Center(
              child: Text(
                'No rentals to manage.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (provider.isLoading) const LinearProgressIndicator(),

        if (provider.errorMessage != null)
          MaterialBanner(
            content: Text(provider.errorMessage!),
            actions: [
              TextButton(
                onPressed: provider.clearFeedback,
                child: const Text('Dismiss'),
              ),
            ],
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshRentals,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount:
                  provider.rentals.length +
                  (provider.hasMore || provider.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                if (index == provider.rentals.length) {
                  if (provider.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: provider.loadMoreRentals,
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more rentals'),
                  );
                }

                final Rental rental = provider.rentals[index];

                return _AdminRentalCard(
                  rental: rental,
                  startDate: _formatDate(rental.startDate),
                  endDate: _formatDate(rental.endDate),
                  statusColor: _statusColor(rental.status),
                  isUpdating: provider.updatingRentalId == rental.id,
                  onUpdate: () {
                    _updateRental(rental);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminRentalCard extends StatelessWidget {
  final Rental rental;
  final String startDate;
  final String endDate;
  final Color statusColor;
  final bool isUpdating;
  final VoidCallback onUpdate;

  const _AdminRentalCard({
    required this.rental,
    required this.startDate,
    required this.endDate,
    required this.statusColor,
    required this.isUpdating,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final bool canUpdate =
        rental.status == 'CONFIRMED' || rental.status == 'PICKED_UP';

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.primaryYellow,
                  child: Icon(Icons.car_rental),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.carName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        rental.customerEmail.isEmpty
                            ? 'Customer'
                            : rental.customerEmail,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
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

            const Divider(height: 26),

            _RentalInfoRow(icon: Icons.tag, text: 'Rental #${rental.id}'),

            const SizedBox(height: 8),

            _RentalInfoRow(
              icon: Icons.date_range_outlined,
              text: '$startDate → $endDate',
            ),

            const SizedBox(height: 8),

            _RentalInfoRow(
              icon: Icons.attach_money,
              text: 'Total: \$${rental.totalPrice.toStringAsFixed(2)}',
            ),

            if (rental.damageCost > 0) ...[
              const SizedBox(height: 8),
              _RentalInfoRow(
                icon: Icons.car_crash_outlined,
                text: 'Damage: \$${rental.damageCost.toStringAsFixed(2)}',
              ),
            ],

            if (canUpdate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isUpdating ? null : onUpdate,
                  icon: isUpdating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          rental.status == 'CONFIRMED'
                              ? Icons.key_outlined
                              : Icons.task_alt,
                        ),
                  label: Text(
                    isUpdating
                        ? 'Updating...'
                        : rental.status == 'CONFIRMED'
                        ? 'Mark Picked Up'
                        : 'Complete Rental',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RentalInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RentalInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppTheme.primaryBlue),
        const SizedBox(width: 9),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _AdminRentalsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminRentalsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load rentals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
