import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/rental.dart';
import '../providers/rental_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class RentalDetailsScreen extends StatefulWidget {
  final Rental rental;

  const RentalDetailsScreen({super.key, required this.rental});

  @override
  State<RentalDetailsScreen> createState() => _RentalDetailsScreenState();
}

class _RentalDetailsScreenState extends State<RentalDetailsScreen> {
  late Rental _rental;

  @override
  void initState() {
    super.initState();
    _rental = widget.rental;
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');

    final String day = date.day.toString().padLeft(2, '0');

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

  Future<void> _shareRental() async {
    await SharePlus.instance.share(
      ShareParams(
        subject: 'Car rental #${_rental.id}',
        text:
        'Rental #${_rental.id}\n'
            'Car: ${_rental.carName}\n'
            'Dates: ${_formatDate(_rental.startDate)}'
            ' - ${_formatDate(_rental.endDate)}\n'
            'Status: ${_rental.status}\n'
            'Total: \$${_rental.totalPrice.toStringAsFixed(2)}',
      ),
    );
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

    final RentalsProvider provider = context.read<RentalsProvider>();

    final Rental? updatedRental = await provider.payDeposit(_rental.id);

    if (!mounted) {
      return;
    }

    if (updatedRental == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Unable to pay booking deposit.',
          ),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _rental = updatedRental;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deposit paid and rental confirmed.'),
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
          content: const Text('Are you sure you want to cancel this rental?'),
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

    final RentalsProvider provider = context.read<RentalsProvider>();

    final bool success = await provider.cancelRental(_rental.id);

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Unable to cancel rental.'),
          backgroundColor: Colors.red,
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rental cancelled successfully.'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatScreen(
              rentalId: _rental.id,
              otherUserName: _isAdmin ? _rental.customerEmail : 'Car Rental Admin',
            ),
      ),
    );
  }

  bool get _isAdmin => AuthService.currentUser?.isAdmin == true;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int get _days =>
      _day(_rental.endDate).difference(_day(_rental.startDate)).inDays + 1;

  // One plain sentence about what happens next.
  String _nextStep() {
    final DateTime today = _day(DateTime.now());
    final int toStart = _day(_rental.startDate).difference(today).inDays;
    final int toEnd = _day(_rental.endDate).difference(today).inDays;

    String when(int days) => days <= 0
        ? 'today'
        : (days == 1 ? 'tomorrow' : 'in $days days');

    switch (_rental.status) {
      case 'PENDING':
        return _isAdmin
            ? 'Waiting for the customer to pay the deposit.'
            : 'Pay the deposit to hold these dates.';
      case 'CONFIRMED':
        return 'Pickup ${when(toStart)}. '
            '${_isAdmin ? 'Check the licence at handover.' : 'Bring your driving licence.'}';
      case 'PICKED_UP':
        return toEnd < 0
            ? 'Return is ${-toEnd} day${toEnd == -1 ? '' : 's'} late.'
            : 'On the road. Return ${when(toEnd)}.';
      case 'COMPLETED':
        return 'Trip finished. Thanks for driving with us.';
      case 'CANCELLED':
        return 'This booking was cancelled.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider = context.watch<RentalsProvider>();

    final bool isPaying = provider.payingDepositRentalId == _rental.id;
    final bool isCancelling = provider.cancellingRentalId == _rental.id;

    final bool canPay =
        !_isAdmin && _rental.status == 'PENDING' && !_rental.depositPaid;
    final bool canCancel = !_isAdmin &&
        (_rental.status == 'PENDING' || _rental.status == 'CONFIRMED');
    final bool canChat = _rental.status != 'CANCELLED';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Car photo that shrinks into the app bar on scroll.
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: AppTheme.darkColor,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(
              'Rental #${_rental.id}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              IconButton(
                tooltip: 'Share rental',
                onPressed: _shareRental,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
                icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroPhoto(
                carId: _rental.carId,
                carName: _rental.carName,
                status: _rental.status,
                statusColor: _statusColor(_rental.status),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // What happens next, in one line.
                _NextStepBanner(text: _nextStep(), status: _rental.status),

                const SizedBox(height: 16),

                _StatusTimeline(
                  status: _rental.status,
                  depositPaid: _rental.depositPaid,
                ),

                const SizedBox(height: 22),
                const _SectionLabel('TRIP'),
                const SizedBox(height: 10),
                _TripCard(
                  start: _rental.startDate,
                  end: _rental.endDate,
                  days: _days,
                  months: _months,
                  weekdays: _weekdays,
                ),

                const SizedBox(height: 22),
                const _SectionLabel('PAYMENT'),
                const SizedBox(height: 10),
                _ReceiptCard(rental: _rental, days: _days),

                if (_isAdmin) ...[
                  const SizedBox(height: 22),
                  const _SectionLabel('CUSTOMER'),
                  const SizedBox(height: 10),
                  _InfoTile(
                    icon: Icons.person_outline_rounded,
                    title: _rental.customerEmail,
                    subtitle: 'Booked this car',
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),

      // Actions live in a fixed bar, always within thumb reach.
      bottomNavigationBar: (canPay || canCancel || canChat)
          ? SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: AppTheme.cardColor,
            border: Border(top: BorderSide(color: AppTheme.borderSoft)),
          ),
          child: Row(
            children: [
              if (canCancel) ...[
                IconButton(
                  tooltip: 'Cancel rental',
                  onPressed: isCancelling ? null : _cancelRental,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    side: const BorderSide(color: AppTheme.errorSoft),
                  ),
                  icon: isCancelling
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(
                    Icons.close_rounded,
                    color: AppTheme.errorDark,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (canChat && !canPay) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openChat,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(
                      _isAdmin ? 'MESSAGE CUSTOMER' : 'MESSAGE SUPPORT',
                    ),
                  ),
                ),
              ],
              if (canPay)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isPaying ? null : _payDeposit,
                    icon: isPaying
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.lock_outline_rounded),
                    label: Text(
                      isPaying
                          ? 'PROCESSING...'
                          : 'PAY \$${_rental.bookingDeposit.toStringAsFixed(2)} DEPOSIT',
                    ),
                  ),
                ),
            ],
          ),
        ),
      )
          : null,
    );
  }
}

/*
 * ---------- Header photo ----------
 * The car's real photo from the server (the image link is public),
 * with a dark fade so the white text stays readable.
 */
class _HeroPhoto extends StatelessWidget {
  final int? carId;
  final String carName;
  final String status;
  final Color statusColor;

  const _HeroPhoto({
    required this.carId,
    required this.carName,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (carId != null)
          Image.network(
            '${ApiClient.baseUrl}/car/image/$carId',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _PhotoFallback(),
          )
        else
          const _PhotoFallback(),

        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x99000000),
                Color(0x00000000),
                Color(0xE6000000),
              ],
              stops: [0, 0.4, 1],
            ),
          ),
        ),

        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                carName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkSoft,
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_car_filled_rounded,
        size: 96,
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }
}

/*
 * ---------- Next step ----------
 */
class _NextStepBanner extends StatelessWidget {
  final String text;
  final String status;

  const _NextStepBanner({required this.text, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool urgent = status == 'PENDING' || text.contains('late');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: urgent ? AppTheme.primaryYellowSoft : AppTheme.primaryBlueSoft,
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
        border: Border.all(
          color: urgent ? AppTheme.primaryYellowStrong : AppTheme.primaryBlueSoft,
        ),
      ),
      child: Row(
        children: [
          Icon(
            urgent ? Icons.priority_high_rounded : Icons.info_outline_rounded,
            size: 20,
            color: urgent ? const Color(0xFF806900) : AppTheme.primaryBlueDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.darkColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
 * ---------- Trip ----------
 * Pickup and return like a flight: two big dates and the length between.
 */
class _TripCard extends StatelessWidget {
  final DateTime start;
  final DateTime end;
  final int days;
  final List<String> months;
  final List<String> weekdays;

  const _TripCard({
    required this.start,
    required this.end,
    required this.days,
    required this.months,
    required this.weekdays,
  });

  Widget _point(String label, DateTime date, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${date.day} ${months[date.month - 1]}',
          style: const TextStyle(
            color: AppTheme.darkColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        Text(
          '${weekdays[date.weekday - 1]} · ${date.year}',
          style: const TextStyle(
            color: AppTheme.mutedColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderSoft),
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      ),
      child: Row(
        children: [
          _point('PICKUP', start, CrossAxisAlignment.start),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  Text(
                    '$days day${days == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: AppTheme.primaryBlueDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 7, color: AppTheme.primaryBlue),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: AppTheme.primaryBlueSoft,
                        ),
                      ),
                      const Icon(
                        Icons.directions_car_rounded,
                        size: 18,
                        color: AppTheme.primaryBlue,
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          color: AppTheme.primaryBlueSoft,
                        ),
                      ),
                      const Icon(Icons.flag_rounded, size: 14, color: AppTheme.primaryBlue),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _point('RETURN', end, CrossAxisAlignment.end),
        ],
      ),
    );
  }
}

/*
 * ---------- Payment receipt ----------
 */
class _ReceiptCard extends StatelessWidget {
  final Rental rental;
  final int days;

  const _ReceiptCard({required this.rental, required this.days});

  @override
  Widget build(BuildContext context) {
    final double dueAtPickup =
    (rental.totalPrice - (rental.depositPaid ? rental.bookingDeposit : 0))
        .clamp(0, double.infinity)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderSoft),
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      ),
      child: Column(
        children: [
          _ReceiptLine(
            label: 'Rental · $days day${days == 1 ? '' : 's'}',
            value: '\$${rental.totalPrice.toStringAsFixed(2)}',
            strong: true,
          ),
          const SizedBox(height: 10),
          _ReceiptLine(
            label: 'Booking deposit',
            value: '\$${rental.bookingDeposit.toStringAsFixed(2)}',
            tag: rental.depositPaid ? 'PAID' : 'DUE',
            tagColor: rental.depositPaid ? AppTheme.successColor : const Color(0xFF806900),
            tagBackground:
            rental.depositPaid ? AppTheme.successSoft : AppTheme.primaryYellowSoft,
          ),
          const SizedBox(height: 10),
          _ReceiptLine(
            label: 'Security deposit',
            value: '\$${rental.securityDeposit.toStringAsFixed(2)}',
            hint: 'Held at pickup, refunded on return',
          ),
          if (rental.damageCost > 0) ...[
            const SizedBox(height: 10),
            _ReceiptLine(
              label: 'Damage',
              value: '\$${rental.damageCost.toStringAsFixed(2)}',
              valueColor: AppTheme.errorDark,
            ),
          ],
          const SizedBox(height: 12),
          const _DashedLine(),
          const SizedBox(height: 12),
          _ReceiptLine(
            label: rental.status == 'COMPLETED' ? 'Paid in total' : 'Due at pickup',
            value: rental.status == 'COMPLETED'
                ? '\$${(rental.totalPrice + rental.damageCost).toStringAsFixed(2)}'
                : '\$${dueAtPickup.toStringAsFixed(2)}',
            strong: true,
            large: true,
          ),
        ],
      ),
    );
  }
}

class _ReceiptLine extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final String? tag;
  final Color? tagColor;
  final Color? tagBackground;
  final Color? valueColor;
  final bool strong;
  final bool large;

  const _ReceiptLine({
    required this.label,
    required this.value,
    this.hint,
    this.tag,
    this.tagColor,
    this.tagBackground,
    this.valueColor,
    this.strong = false,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: strong ? AppTheme.darkColor : AppTheme.textColor,
                        fontSize: large ? 15 : 14,
                        fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag!,
                        style: TextStyle(
                          color: tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    hint!,
                    style: const TextStyle(
                      color: AppTheme.mutedColor,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppTheme.darkColor,
            fontSize: large ? 20 : 14,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            letterSpacing: large ? -0.5 : 0,
          ),
        ),
      ],
    );
  }
}

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter()),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.borderColor
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + 4, 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => false;
}

/*
 * ---------- Small pieces ----------
 */
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.primaryBlueDark,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.3,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderSoft),
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.darkColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.mutedColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
 * The rental lifecycle as a visual path:
 * Booked -> Deposit -> Picked up -> Returned.
 * Finished steps are blue with a check, the current step is yellow,
 * later steps are grey. A cancelled rental stops where it was.
 */
class _StatusTimeline extends StatelessWidget {
  final String status;
  final bool depositPaid;

  const _StatusTimeline({
    required this.status,
    required this.depositPaid,
  });

  static const List<String> _labels = [
    'Booked',
    'Deposit',
    'Picked up',
    'Returned',
  ];

  static const List<IconData> _icons = [
    Icons.edit_calendar_outlined,
    Icons.payments_outlined,
    Icons.key_outlined,
    Icons.flag_outlined,
  ];

  // How many steps are finished.
  int get _doneSteps {
    switch (status) {
      case 'PENDING':
        return 1;
      case 'CONFIRMED':
        return 2;
      case 'PICKED_UP':
        return 3;
      case 'COMPLETED':
        return 4;
      case 'CANCELLED':
        return depositPaid ? 2 : 1;
      default:
        return 0;
    }
  }

  bool get _isCancelled => status == 'CANCELLED';

  @override
  Widget build(BuildContext context) {
    final int done = _doneSteps;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderSoft),
        borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      ),
      child: Column(
        children: [
          Row(
            children: List<Widget>.generate(_labels.length * 2 - 1, (index) {
              // Even positions are steps, odd positions are the lines between.
              if (index.isOdd) {
                final int leftStep = index ~/ 2;
                final bool filled = leftStep + 1 < done ||
                    (leftStep + 1 == done && !_isCancelled && done < 4);

                return Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: filled ? 1 : 0),
                    duration: Duration(milliseconds: 350 + leftStep * 150),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return Container(
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 22),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: const [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue,
                              AppTheme.borderSoft,
                              AppTheme.borderSoft,
                            ],
                            stops: [0, value, value, 1],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              final int step = index ~/ 2;
              return _StepDot(
                icon: _icons[step],
                label: _labels[step],
                isDone: step < done && !(step == done - 1 && _isCancelled),
                isCurrent: !_isCancelled && step == done && done < 4,
                isCancelPoint: _isCancelled && step == done - 1,
                delay: step,
              );
            }),
          ),

          if (_isCancelled) ...[
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 15,
                  color: AppTheme.errorColor,
                ),
                SizedBox(width: 6),
                Text(
                  'This rental was cancelled',
                  style: TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDone;
  final bool isCurrent;
  final bool isCancelPoint;
  final int delay;

  const _StepDot({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isCurrent,
    required this.isCancelPoint,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final Color background;
    final Color foreground;
    final Color border;
    final IconData shownIcon;

    if (isCancelPoint) {
      background = AppTheme.errorSoft;
      foreground = AppTheme.errorColor;
      border = AppTheme.errorColor;
      shownIcon = Icons.close;
    } else if (isDone) {
      background = AppTheme.primaryBlue;
      foreground = Colors.white;
      border = AppTheme.primaryBlue;
      shownIcon = Icons.check;
    } else if (isCurrent) {
      background = AppTheme.primaryYellow;
      foreground = AppTheme.darkColor;
      border = AppTheme.primaryYellowStrong;
      shownIcon = icon;
    } else {
      background = AppTheme.cardColor;
      foreground = AppTheme.mutedColor;
      border = AppTheme.borderSoft;
      shownIcon = icon;
    }

    return SizedBox(
      width: 62,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.6, end: 1),
            duration: Duration(milliseconds: 300 + delay * 120),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 2),
                boxShadow: isCurrent
                    ? [
                  BoxShadow(
                    color: AppTheme.primaryYellow.withValues(alpha: 0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
                    : null,
              ),
              child: Icon(shownIcon, size: 17, color: foreground),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isCurrent || isDone ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent || isDone
                  ? AppTheme.darkColor
                  : AppTheme.mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
