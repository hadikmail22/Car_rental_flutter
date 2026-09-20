import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rental.dart';
import '../providers/rental_provider.dart';
import '../theme/app_theme.dart';
import 'rental_details_screen.dart';

class RentalHistoryScreen extends StatefulWidget {
  const RentalHistoryScreen({super.key});

  @override
  State<RentalHistoryScreen> createState() {
    return _RentalHistoryScreenState();
  }
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

  int _rentalDays(Rental rental) {
    return rental.endDate.difference(rental.startDate).inDays + 1;
  }

  _HistoryStatusStyle _statusStyle(String status) {
    switch (status) {
      case 'COMPLETED':
        return const _HistoryStatusStyle(
          label: 'COMPLETED',
          icon: Icons.check_circle_outline_rounded,
          foreground: AppTheme.successColor,
          background: AppTheme.successSoft,
        );

      case 'CANCELLED':
        return const _HistoryStatusStyle(
          label: 'CANCELLED',
          icon: Icons.cancel_outlined,
          foreground: AppTheme.errorDark,
          background: AppTheme.errorSoft,
        );

      default:
        return _HistoryStatusStyle(
          label: status,
          icon: Icons.history_rounded,
          foreground: AppTheme.mutedColor,
          background: AppTheme.borderSoft,
        );
    }
  }

  void _openRentalDetails(Rental rental) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return RentalDetailsScreen(rental: rental);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider = context.watch<RentalsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rental History')),
      body: Column(
        children: [
          _HistoryHeader(totalRentals: provider.totalHistoryRentals),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(RentalsProvider provider) {
    if (provider.isLoadingHistory && provider.historyRentals.isEmpty) {
      return const _HistoryLoadingState();
    }

    if (provider.historyErrorMessage != null &&
        provider.historyRentals.isEmpty) {
      return _HistoryMessageState(
        icon: Icons.cloud_off_outlined,
        title: 'Unable to load history',
        message: provider.historyErrorMessage!,
        buttonText: 'TRY AGAIN',
        onPressed: provider.loadRentalHistory,
      );
    }

    if (provider.isHistoryEmpty) {
      return _HistoryMessageState(
        icon: Icons.history_rounded,
        title: 'No rental history yet',
        message: 'Your completed and cancelled rentals will appear here.',
        buttonText: 'REFRESH HISTORY',
        onPressed: provider.loadRentalHistory,
      );
    }

    return Column(
      children: [
        if (provider.isLoadingHistory)
          const LinearProgressIndicator(minHeight: 3),
        if (provider.historyErrorMessage != null)
          _HistoryErrorBanner(
            message: provider.historyErrorMessage!,
            onClose: provider.clearHistoryError,
          ),
        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: provider.refreshRentalHistory,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
              itemCount:
                  provider.historyRentals.length +
                  (provider.hasMoreHistory || provider.isLoadingMoreHistory
                      ? 1
                      : 0),
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 14);
              },
              itemBuilder: (BuildContext context, int index) {
                if (index == provider.historyRentals.length) {
                  if (provider.isLoadingMoreHistory) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed: provider.loadMoreRentalHistory,
                    icon: const Icon(Icons.expand_more_rounded),
                    label: const Text('LOAD MORE HISTORY'),
                  );
                }

                final Rental rental = provider.historyRentals[index];

                return _HistoryRentalCard(
                  rental: rental,
                  formattedStartDate: _formatDate(rental.startDate),
                  formattedEndDate: _formatDate(rental.endDate),
                  rentalDays: _rentalDays(rental),
                  statusStyle: _statusStyle(rental.status),
                  onTap: () {
                    _openRentalDetails(rental);
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

class _HistoryHeader extends StatelessWidget {
  final int totalRentals;

  const _HistoryHeader({required this.totalRentals});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primaryYellowSoft,
              borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
              border: Border.all(color: AppTheme.primaryYellowStrong),
            ),
            child: const Icon(
              Icons.history_rounded,
              color: AppTheme.primaryBlueDark,
              size: 27,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAST RENTALS',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  'Your rental archive',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Review completed and cancelled bookings.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            constraints: const BoxConstraints(minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(AppTheme.smallRadius),
              border: Border.all(color: AppTheme.primaryBlue),
            ),
            child: Column(
              children: [
                Text(
                  '$totalRentals',
                  style: const TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRentalCard extends StatelessWidget {
  final Rental rental;
  final String formattedStartDate;
  final String formattedEndDate;
  final int rentalDays;
  final _HistoryStatusStyle statusStyle;
  final VoidCallback onTap;

  const _HistoryRentalCard({
    required this.rental,
    required this.formattedStartDate,
    required this.formattedEndDate,
    required this.rentalDays,
    required this.statusStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(height: 5, color: statusStyle.foreground),
            Padding(
              padding: const EdgeInsets.all(17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlueSoft,
                          borderRadius: BorderRadius.circular(
                            AppTheme.smallRadius,
                          ),
                        ),
                        child: const Icon(
                          Icons.directions_car_filled_rounded,
                          color: AppTheme.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rental.carName.isEmpty
                                  ? 'Rental #${rental.id}'
                                  : rental.carName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'RENTAL #${rental.id}',
                              style: const TextStyle(
                                color: AppTheme.mutedColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(style: statusStyle),
                    ],
                  ),
                  const SizedBox(height: 17),
                  const Divider(height: 1),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(
                        child: _DateBox(
                          label: 'PICKUP',
                          date: formattedStartDate,
                          icon: Icons.login_rounded,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: AppTheme.primaryBlue,
                              size: 20,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$rentalDays ${rentalDays == 1 ? 'DAY' : 'DAYS'}',
                              style: const TextStyle(
                                color: AppTheme.mutedColor,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _DateBox(
                          label: 'RETURN',
                          date: formattedEndDate,
                          icon: Icons.logout_rounded,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 17),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                      border: Border.all(color: AppTheme.borderSoft),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          color: AppTheme.primaryBlue,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'FINAL RENTAL TOTAL',
                            style: TextStyle(
                              color: AppTheme.mutedColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Text(
                          '\$${rental.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.primaryBlueDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rental.damageCost > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorSoft,
                        borderRadius: BorderRadius.circular(
                          AppTheme.smallRadius,
                        ),
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.car_crash_outlined,
                            color: AppTheme.errorDark,
                            size: 19,
                          ),
                          const SizedBox(width: 9),
                          const Expanded(
                            child: Text(
                              'Damage cost',
                              style: TextStyle(
                                color: AppTheme.errorDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            '\$${rental.damageCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.errorDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'VIEW DETAILS',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppTheme.primaryBlueDark),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.primaryBlue,
                        size: 19,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final bool alignEnd;

  const _DateBox({
    required this.label,
    required this.date,
    required this.icon,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: alignEnd
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 15),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          date,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: AppTheme.darkColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _HistoryStatusStyle style;

  const _StatusBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, color: style.foreground, size: 14),
          const SizedBox(width: 5),
          Text(
            style.label,
            style: TextStyle(
              color: style.foreground,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _HistoryErrorBanner({required this.message, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
        border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorDark,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: AppTheme.errorDark),
          ),
        ],
      ),
    );
  }
}

class _HistoryLoadingState extends StatelessWidget {
  const _HistoryLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (BuildContext context, int index) {
        return const SizedBox(height: 14);
      },
      itemBuilder: (BuildContext context, int index) {
        return Container(
          height: 230,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
            border: Border.all(color: AppTheme.borderSoft),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _HistoryMessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const _HistoryMessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: () async {
        onPressed();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueSoft,
                borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                border: Border.all(color: AppTheme.primaryBlue),
              ),
              child: Icon(icon, size: 42, color: AppTheme.primaryBlue),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(buttonText),
          ),
        ],
      ),
    );
  }
}

class _HistoryStatusStyle {
  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  const _HistoryStatusStyle({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });
}
