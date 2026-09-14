import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rental.dart';
import '../providers/rental_provider.dart';
import '../theme/app_theme.dart';
import 'rental_details_screen.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() => _RentalHistoryScreenState();
}

class _RentalHistoryScreenState extends State<RentalHistoryScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalsProvider>().loadRentalHistory();
    });
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;

      case 'CANCELLED':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider = context.watch<RentalsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rental History (${provider.totalHistoryRentals})',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(RentalsProvider provider) {
    if (provider.isLoadingHistory && provider.historyRentals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.historyErrorMessage != null &&
        provider.historyRentals.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load history',
        message: provider.historyErrorMessage!,
        buttonText: 'Try again',
        onPressed: provider.loadRentalHistory,
      );
    }

    if (provider.isHistoryEmpty) {
      return _MessageState(
        icon: Icons.history,
        title: 'No rental history',
        message: 'Completed and cancelled rentals will appear here.',
        buttonText: 'Refresh',
        onPressed: provider.loadRentalHistory,
      );
    }

    return Column(
      children: [
        if (provider.isLoadingHistory) const LinearProgressIndicator(),

        if (provider.historyErrorMessage != null)
          MaterialBanner(
            content: Text(provider.historyErrorMessage!),
            actions: [
              TextButton(
                onPressed: provider.clearHistoryError,
                child: const Text('Dismiss'),
              ),
            ],
          ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: provider.refreshRentalHistory,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount:
                  provider.historyRentals.length +
                  (provider.hasMoreHistory || provider.isLoadingMoreHistory
                      ? 1
                      : 0),
              separatorBuilder: (context, index) {
                return const SizedBox(height: 12);
              },
              itemBuilder: (context, index) {
                if (index == provider.historyRentals.length) {
                  if (provider.isLoadingMoreHistory) {
                    return const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: provider.loadMoreRentalHistory,
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more history'),
                  );
                }

                final Rental rental = provider.historyRentals[index];

                final Color statusColor = _statusColor(rental.status);

                return Card(
                  color: Colors.white,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RentalDetailsScreen(rental: rental),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.car_rental,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  rental.carName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                          const Divider(height: 24),
                          Text(
                            '${_formatDate(rental.startDate)}'
                            ' → '
                            '${_formatDate(rental.endDate)}',
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
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            OutlinedButton(onPressed: onPressed, child: Text(buttonText)),
          ],
        ),
      ),
    );
  }
}
