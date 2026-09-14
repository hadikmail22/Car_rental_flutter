import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rental.dart';
import '../providers/rental_provider.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class RentalDetailsScreen extends StatefulWidget {
  final Rental rental;

  const RentalDetailsScreen({
    super.key,
    required this.rental,
  });

  @override
  State<RentalDetailsScreen> createState() =>
      _RentalDetailsScreenState();
}

class _RentalDetailsScreenState
    extends State<RentalDetailsScreen> {
  late Rental _rental;

  @override
  void initState() {
    super.initState();
    _rental = widget.rental;
  }

  String _formatDate(DateTime date) {
    final String month =
    date.month.toString().padLeft(2, '0');

    final String day =
    date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

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

  Future<void> _payDeposit() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pay Booking Deposit'),
          content: Text(
            'Confirm payment of '
                '\$${_rental.bookingDeposit.toStringAsFixed(2)}?',
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
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final RentalsProvider provider =
    context.read<RentalsProvider>();

    final Rental? updatedRental =
    await provider.payDeposit(_rental.id);

    if (!mounted) {
      return;
    }

    if (updatedRental == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Unable to pay booking deposit.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    setState(() {
      _rental = updatedRental;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Deposit paid and rental confirmed',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _cancelRental() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Rental'),
          content: const Text(
            'Are you sure you want to cancel this rental?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Rental'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final RentalsProvider provider =
    context.read<RentalsProvider>();

    final bool success =
    await provider.cancelRental(_rental.id);

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ??
                'Unable to cancel rental.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rental cancelled successfully'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          rentalId: _rental.id,
          otherUserName: 'Car Rental Admin',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider =
    context.watch<RentalsProvider>();

    final Color statusColor =
    _statusColor(_rental.status);

    final bool isPaying =
        provider.payingDepositRentalId == _rental.id;

    final bool isCancelling =
        provider.cancellingRentalId == _rental.id;

    final bool canCancel =
        _rental.status == 'PENDING';

    return Scaffold(
      appBar: AppBar(
        title: Text('Rental #${_rental.id}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.car_rental,
                  size: 70,
                ),
                const SizedBox(height: 10),
                Text(
                  _rental.carName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _rental.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 22),

          _DetailRow(
            title: 'Start Date',
            value: _formatDate(_rental.startDate),
          ),

          _DetailRow(
            title: 'End Date',
            value: _formatDate(_rental.endDate),
          ),

          _DetailRow(
            title: 'Total Price',
            value:
            '\$${_rental.totalPrice.toStringAsFixed(2)}',
          ),

          _DetailRow(
            title: 'Booking Deposit',
            value:
            '\$${_rental.bookingDeposit.toStringAsFixed(2)}',
          ),

          _DetailRow(
            title: 'Security Deposit',
            value:
            '\$${_rental.securityDeposit.toStringAsFixed(2)}',
          ),

          _DetailRow(
            title: 'Deposit Status',
            value:
            _rental.depositPaid ? 'Paid' : 'Not Paid',
          ),

          const SizedBox(height: 20),

          if (_rental.status == 'PENDING' &&
              !_rental.depositPaid)
            ElevatedButton.icon(
              onPressed: isPaying
                  ? null
                  : _payDeposit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: isPaying
                  ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.payment),
              label: Text(
                isPaying
                    ? 'Processing Payment...'
                    : 'Pay Deposit',
              ),
            ),

          if (canCancel) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isCancelling
                  ? null
                  : _cancelRental,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: isCancelling
                  ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.cancel_outlined),
              label: Text(
                isCancelling
                    ? 'Cancelling...'
                    : 'Cancel Rental',
              ),
            ),
          ],

          if (_rental.status != 'CANCELLED') ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openChat,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(
                Icons.chat_bubble_outline,
              ),
              label: const Text('Message Admin'),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String title;
  final String value;

  const _DetailRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Row(
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
      ),
    );
  }
}