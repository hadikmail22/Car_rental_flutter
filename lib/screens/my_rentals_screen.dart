import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/rental.dart';
import '../providers/rental_provider.dart';
import '../theme/app_theme.dart';
import 'rental_details_screen.dart';
import 'rental_history_screen.dart';

/*
 * My Rentals, redesigned around "what happens next".
 *
 *  1. An "Up next" card for the most urgent rental:
 *     pay the deposit, pick the car up, or bring it back.
 *     It counts the days and shows the trip progress.
 *  2. Filter chips: all, awaiting payment, upcoming, on the road.
 *  3. The other rentals as boarding-pass style tickets,
 *     with the right action on each one.
 */
class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() => _MyRentalsScreenState();
}

enum _Filter { all, payment, upcoming, onRoad }

class _MyRentalsScreenState extends State<MyRentalsScreen> {
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalsProvider>().loadRentals();
    });
  }

  // ---------- Date helpers ----------

  static DateTime _day(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _daysFromToday(DateTime date) =>
      _day(date).difference(_day(DateTime.now())).inDays;

  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static String _short(DateTime date) =>
      '${date.day} ${_months[date.month - 1]}';

  // ---------- Which rental is most urgent ----------

  /*
   * The rental with the nearest upcoming date:
   *  - a car you have now   -> its return date
   *  - confirmed or pending -> its pickup date
   * An overdue return has a date in the past,
   * so it naturally comes first.
   */
  static DateTime? _nextDate(Rental rental) {
    switch (rental.status) {
      case 'PICKED_UP':
        return _day(rental.endDate);
      case 'CONFIRMED':
      case 'PENDING':
        return _day(rental.startDate);
      default:
        return null;
    }
  }

  Rental? _upNext(List<Rental> rentals) {
    final List<Rental> candidates = rentals
        .where((Rental rental) => _nextDate(rental) != null)
        .toList()
      ..sort((Rental a, Rental b) {
        final int byDate = _nextDate(a)!.compareTo(_nextDate(b)!);

        if (byDate != 0) {
          return byDate;
        }

        // Same day: a return comes before a pickup.
        return (a.status == 'PICKED_UP' ? 0 : 1)
            .compareTo(b.status == 'PICKED_UP' ? 0 : 1);
      });

    return candidates.isEmpty ? null : candidates.first;
  }

  bool _passesFilter(Rental rental) {
    switch (_filter) {
      case _Filter.all:
        return true;
      case _Filter.payment:
        return rental.status == 'PENDING';
      case _Filter.upcoming:
        return rental.status == 'CONFIRMED';
      case _Filter.onRoad:
        return rental.status == 'PICKED_UP';
    }
  }

  // ---------- Actions ----------

  void _openDetails(Rental rental) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RentalDetailsScreen(rental: rental),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const RentalHistoryScreen()),
    );
  }

  Future<void> _payDeposit(RentalsProvider provider, Rental rental) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Pay booking deposit'),
          content: Text(
            'Pay \$${rental.bookingDeposit.toStringAsFixed(2)} to confirm '
                'the ${rental.carName}. The dates are only held '
                'once the deposit is paid.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('NOT NOW'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 44),
              ),
              child: const Text('PAY'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final Rental? updated = await provider.payDeposit(rental.id);

    if (!mounted) {
      return;
    }

    if (updated != null) {
      HapticFeedback.mediumImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated != null
              ? 'Deposit paid. Your ${rental.carName} is confirmed.'
              : provider.errorMessage ?? 'Payment failed.',
        ),
        backgroundColor:
        updated != null ? AppTheme.successColor : AppTheme.errorColor,
      ),
    );
  }

  Future<void> _cancel(RentalsProvider provider, Rental rental) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel rental?'),
          content: Text('Cancel the ${rental.carName} booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('KEEP IT'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('CANCEL RENTAL'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final bool success = await provider.cancelRental(rental.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Rental cancelled.'
              : provider.errorMessage ?? 'Failed to cancel rental.',
        ),
        backgroundColor: success ? null : AppTheme.errorColor,
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider = context.watch<RentalsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: 'Past trips',
              onPressed: _openHistory,
              icon: const Icon(Icons.history_rounded),
            ),
          ),
        ],
      ),
      body: _buildBody(provider),
    );
  }

  Widget _buildBody(RentalsProvider provider) {
    if (provider.isLoading && provider.rentals.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && provider.rentals.isEmpty) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load rentals',
        message: provider.errorMessage!,
        actionLabel: 'TRY AGAIN',
        onAction: provider.loadRentals,
      );
    }

    if (provider.rentals.isEmpty) {
      return _EmptyState(
        icon: Icons.directions_car_outlined,
        title: 'No active rentals',
        message: 'Pick a car from the fleet and your booking will show up here.',
        actionLabel: 'PAST TRIPS',
        onAction: () async => _openHistory(),
      );
    }

    final Rental? next = _upNext(provider.rentals);

    final List<Rental> others = provider.rentals
        .where((Rental rental) => rental.id != next?.id)
        .where(_passesFilter)
        .toList()
    // Same order as "Up next": nearest date first.
      ..sort((Rental a, Rental b) {
        final DateTime? dateA = _nextDate(a);
        final DateTime? dateB = _nextDate(b);

        if (dateA == null || dateB == null) {
          return 0;
        }

        return dateA.compareTo(dateB);
      });

    return RefreshIndicator(
      onRefresh: provider.refreshRentals,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          if (next != null) ...[
            const _Label('UP NEXT'),
            const SizedBox(height: 10),
            _UpNextCard(
              rental: next,
              isPaying: provider.payingDepositRentalId == next.id,
              onOpen: () => _openDetails(next),
              onPay: () => _payDeposit(provider, next),
            ),
            const SizedBox(height: 22),
          ],

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', _Filter.all),
                _chip('Awaiting payment', _Filter.payment),
                _chip('Upcoming', _Filter.upcoming),
                _chip('On the road', _Filter.onRoad),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (others.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  _filter == _Filter.all
                      ? 'That is your only active rental.'
                      : 'Nothing here right now.',
                  style: const TextStyle(color: AppTheme.mutedColor),
                ),
              ),
            )
          else
            ...others.map((Rental rental) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _TicketCard(
                  rental: rental,
                  isPaying: provider.payingDepositRentalId == rental.id,
                  isCancelling: provider.cancellingRentalId == rental.id,
                  onOpen: () => _openDetails(rental),
                  onPay: rental.status == 'PENDING' && !rental.depositPaid
                      ? () => _payDeposit(provider, rental)
                      : null,
                  onCancel: rental.status == 'PENDING' ||
                      rental.status == 'CONFIRMED'
                      ? () => _cancel(provider, rental)
                      : null,
                ),
              );
            }),

          if (provider.hasMore) ...[
            const SizedBox(height: 4),
            Center(
              child: provider.isLoadingMore
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              )
                  : TextButton(
                onPressed: provider.loadMoreRentals,
                child: const Text('LOAD MORE'),
              ),
            ),
          ],

          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: _openHistory,
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('VIEW PAST TRIPS'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, _Filter value) {
    final bool selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() {
            _filter = value;
          });
        },
        labelStyle: TextStyle(
          color: selected ? AppTheme.darkColor : AppTheme.primaryBlueDark,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

/*
 * ---------- Up next ----------
 */
class _UpNextCard extends StatelessWidget {
  final Rental rental;
  final bool isPaying;
  final VoidCallback onOpen;
  final VoidCallback onPay;

  const _UpNextCard({
    required this.rental,
    required this.isPaying,
    required this.onOpen,
    required this.onPay,
  });

  // The big line: what is about to happen, in plain words.
  ({String headline, String caption, IconData icon}) _story() {
    final int toStart = _MyRentalsScreenState._daysFromToday(rental.startDate);
    final int toEnd = _MyRentalsScreenState._daysFromToday(rental.endDate);

    String inDays(int days) =>
        days == 0 ? 'today' : (days == 1 ? 'tomorrow' : 'in $days days');

    switch (rental.status) {
      case 'PICKED_UP':
        return (
        headline: toEnd < 0 ? 'Return is overdue' : 'Return ${inDays(toEnd)}',
        caption: toEnd < 0
            ? 'Late days are charged at twice the daily rate.'
            : 'Enjoy the drive. Bring it back by ${_MyRentalsScreenState._short(rental.endDate)}.',
        icon: Icons.route_rounded,
        );
      case 'PENDING':
        return (
        headline: 'Pay the deposit',
        caption: 'Your dates are held only after the deposit is paid.',
        icon: Icons.payments_outlined,
        );
      default:
        return (
        headline: 'Pickup ${inDays(toStart < 0 ? 0 : toStart)}',
        caption: 'Confirmed. Bring your driving licence to the pickup.',
        icon: Icons.key_rounded,
        );
    }
  }

  // Share of the trip already driven, for the progress bar.
  double _tripProgress() {
    final DateTime start = _MyRentalsScreenState._day(rental.startDate);
    final DateTime end = _MyRentalsScreenState._day(rental.endDate);
    final DateTime today = _MyRentalsScreenState._day(DateTime.now());

    final int total = end.difference(start).inDays + 1;
    final int done = today.difference(start).inDays + 1;

    return (done / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final story = _story();
    final bool onRoad = rental.status == 'PICKED_UP';
    final bool needsPayment = rental.status == 'PENDING' && !rental.depositPaid;

    return Material(
      color: AppTheme.darkColor,
      borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryYellow,
                      borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
                    ),
                    child: Icon(story.icon, color: AppTheme.darkColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      story.headline,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Text(
                    '#${rental.id}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                story.caption,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Car and dates, as a route from pickup to return.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rental.carName,
                      style: const TextStyle(
                        color: AppTheme.primaryYellow,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _RoutePoint(
                          label: 'PICKUP',
                          date: _MyRentalsScreenState._short(rental.startDate),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: onRoad
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0,
                                  end: _tripProgress(),
                                ),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) {
                                  return LinearProgressIndicator(
                                    value: value,
                                    minHeight: 5,
                                    backgroundColor:
                                    Colors.white.withValues(alpha: 0.12),
                                    valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryYellow,
                                    ),
                                  );
                                },
                              ),
                            )
                                : Row(
                              children: List<Widget>.generate(8, (i) {
                                return Expanded(
                                  child: Container(
                                    height: 2,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    color: Colors.white
                                        .withValues(alpha: 0.25),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                        _RoutePoint(
                          label: 'RETURN',
                          date: _MyRentalsScreenState._short(rental.endDate),
                          alignEnd: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (needsPayment) ...[
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: isPaying ? null : onPay,
                  icon: isPaying
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.lock_outline_rounded, size: 18),
                  label: Text(
                    isPaying
                        ? 'PROCESSING...'
                        : 'PAY \$${rental.bookingDeposit.toStringAsFixed(0)} DEPOSIT',
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Total \$${rental.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'DETAILS',
                      style: TextStyle(
                        color: AppTheme.primaryYellow,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppTheme.primaryYellow,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  final String label;
  final String date;
  final bool alignEnd;

  const _RoutePoint({
    required this.label,
    required this.date,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          date,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/*
 * ---------- Ticket card ----------
 * Looks like a boarding pass: a date stub on the left,
 * a dashed tear line, then the trip details.
 */
class _TicketCard extends StatelessWidget {
  final Rental rental;
  final bool isPaying;
  final bool isCancelling;
  final VoidCallback onOpen;
  final VoidCallback? onPay;
  final VoidCallback? onCancel;

  const _TicketCard({
    required this.rental,
    required this.isPaying,
    required this.isCancelling,
    required this.onOpen,
    this.onPay,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final _StatusLook look = _StatusLook.of(rental.status);
    final DateTime start = rental.startDate;

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(AppTheme.largeRadius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderSoft),
            borderRadius: BorderRadius.circular(AppTheme.largeRadius),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Date stub.
                Container(
                  width: 74,
                  color: look.soft,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${start.day}',
                        style: TextStyle(
                          color: look.color,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _MyRentalsScreenState._months[start.month - 1],
                        style: TextStyle(
                          color: look.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tear line.
                const _DashedDivider(),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                rental.carName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.darkColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: look.soft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                look.label,
                                style: TextStyle(
                                  color: look.color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_MyRentalsScreenState._short(rental.startDate)}  →  '
                              '${_MyRentalsScreenState._short(rental.endDate)}'
                              '  ·  \$${rental.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.mutedColor,
                            fontSize: 12.5,
                          ),
                        ),
                        if (onPay != null || onCancel != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (onPay != null)
                                _SmallAction(
                                  label: isPaying ? 'PAYING…' : 'PAY DEPOSIT',
                                  icon: Icons.payments_outlined,
                                  filled: true,
                                  onTap: isPaying ? null : onPay,
                                ),
                              if (onPay != null && onCancel != null)
                                const SizedBox(width: 8),
                              if (onCancel != null)
                                _SmallAction(
                                  label: isCancelling ? 'CANCELLING…' : 'CANCEL',
                                  icon: Icons.close_rounded,
                                  danger: true,
                                  onTap: isCancelling ? null : onCancel,
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    // CustomPaint (not LayoutBuilder) so it works inside IntrinsicHeight.
    return const SizedBox(
      width: 1,
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

    for (double y = 4; y < size.height - 4; y += 7) {
      canvas.drawLine(Offset(0.5, y), Offset(0.5, y + 4), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) => false;
}

class _SmallAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final bool danger;
  final VoidCallback? onTap;

  const _SmallAction({
    required this.label,
    required this.icon,
    this.filled = false,
    this.danger = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color foreground = danger
        ? AppTheme.errorDark
        : (filled ? AppTheme.darkColor : AppTheme.primaryBlueDark);

    return Material(
      color: filled ? AppTheme.primaryYellow : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.smallRadius),
            border: Border.all(
              color: filled
                  ? AppTheme.primaryYellowStrong
                  : (danger ? AppTheme.errorSoft : AppTheme.borderSoft),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusLook {
  final String label;
  final Color color;
  final Color soft;

  const _StatusLook(this.label, this.color, this.soft);

  static _StatusLook of(String status) {
    switch (status) {
      case 'PENDING':
        return const _StatusLook(
          'Awaiting payment',
          Color(0xFF806900),
          AppTheme.primaryYellowSoft,
        );
      case 'CONFIRMED':
        return const _StatusLook(
          'Confirmed',
          AppTheme.primaryBlueDark,
          AppTheme.primaryBlueSoft,
        );
      case 'PICKED_UP':
        return const _StatusLook(
          'On the road',
          AppTheme.successColor,
          AppTheme.successSoft,
        );
      case 'COMPLETED':
        return const _StatusLook(
          'Completed',
          AppTheme.mutedColor,
          AppTheme.borderSoft,
        );
      case 'CANCELLED':
        return const _StatusLook(
          'Cancelled',
          AppTheme.errorDark,
          AppTheme.errorSoft,
        );
      default:
        return _StatusLook(status, AppTheme.mutedColor, AppTheme.borderSoft);
    }
  }
}

class _Label extends StatelessWidget {
  final String text;

  const _Label(this.text);

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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlueSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.darkColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
