import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rental.dart';
import '../providers/rental_provider.dart';
import '../theme/app_theme.dart';
import 'rental_details_screen.dart';
import 'rental_history_screen.dart';

class MyRentalsScreen extends StatefulWidget {
  const MyRentalsScreen({super.key});

  @override
  State<MyRentalsScreen> createState() {
    return _MyRentalsScreenState();
  }
}

class _MyRentalsScreenState
    extends State<MyRentalsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RentalsProvider>().loadRentals();
    });
  }

  String _formatDate(DateTime date) {
    final String month =
    date.month.toString().padLeft(2, '0');

    final String day =
    date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  _StatusStyle _statusStyle(String status) {
    switch (status) {
      case 'PENDING':
        return const _StatusStyle(
          foreground: Color(0xFF806900),
          background: AppTheme.primaryYellowSoft,
        );
      case 'CONFIRMED':
        return const _StatusStyle(
          foreground: AppTheme.primaryBlueDark,
          background: AppTheme.primaryBlueSoft,
        );
      case 'PICKED_UP':
        return const _StatusStyle(
          foreground: Color(0xFF6F42C1),
          background: Color(0xFFF0E8FC),
        );
      case 'COMPLETED':
        return const _StatusStyle(
          foreground: AppTheme.successColor,
          background: AppTheme.successSoft,
        );
      case 'CANCELLED':
        return const _StatusStyle(
          foreground: AppTheme.errorDark,
          background: AppTheme.errorSoft,
        );
      default:
        return const _StatusStyle(
          foreground: AppTheme.mutedColor,
          background: AppTheme.borderSoft,
        );
    }
  }

  Future<void> _cancelRental(
      RentalsProvider provider,
      Rental rental,
      ) async {
    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.errorColor,
            size: 46,
          ),
          title: const Text(
            'Cancel Rental',
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Are you sure you want to cancel the '
                '${rental.carName} rental?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('KEEP RENTAL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                AppTheme.errorColor,
                foregroundColor: Colors.white,
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

    final bool success =
    await provider.cancelRental(rental.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Rental cancelled successfully.'
              : provider.errorMessage ??
              'Failed to cancel rental.',
        ),
        backgroundColor: success
            ? AppTheme.successColor
            : AppTheme.errorColor,
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return const RentalHistoryScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RentalsProvider provider =
    context.watch<RentalsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rentals'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 14,
              top: 8,
              bottom: 8,
            ),
            child: IconButton(
              tooltip: 'Rental history',
              onPressed: _openHistory,
              icon: const Icon(
                Icons.history_rounded,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _RentalsHeader(
            totalRentals: provider.totalRentals,
            onHistoryPressed: _openHistory,
          ),
          Expanded(
            child: _buildBody(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RentalsProvider provider) {
    if (provider.isLoading &&
        provider.rentals.isEmpty) {
      return const _LoadingState();
    }

    if (provider.errorMessage != null &&
        provider.rentals.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage!,
        onRetry: provider.loadRentals,
      );
    }

    if (provider.isEmpty) {
      return _EmptyState(
        onRefresh: provider.loadRentals,
      );
    }

    return Column(
      children: [
        if (provider.isLoading)
          const LinearProgressIndicator(
            minHeight: 3,
          ),

        if (provider.errorMessage != null)
          _ErrorBanner(
            message: provider.errorMessage!,
            onClose: provider.clearFeedback,
          ),

        Expanded(
          child: RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: provider.refreshRentals,
            child: ListView.separated(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                28,
              ),
              itemCount:
              provider.rentals.length +
                  (provider.hasMore ||
                      provider.isLoadingMore
                      ? 1
                      : 0),
              separatorBuilder: (
                  BuildContext context,
                  int index,
                  ) {
                return const SizedBox(height: 14);
              },
              itemBuilder: (
                  BuildContext context,
                  int index,
                  ) {
                if (index ==
                    provider.rentals.length) {
                  if (provider.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.all(18),
                      child: Center(
                        child:
                        CircularProgressIndicator(),
                      ),
                    );
                  }

                  return OutlinedButton.icon(
                    onPressed:
                    provider.loadMoreRentals,
                    icon: const Icon(
                      Icons.expand_more_rounded,
                    ),
                    label: const Text(
                      'LOAD MORE RENTALS',
                    ),
                  );
                }

                final Rental rental =
                provider.rentals[index];

                return _RentalCard(
                  rental: rental,
                  statusStyle:
                  _statusStyle(rental.status),
                  startDate:
                  _formatDate(rental.startDate),
                  endDate:
                  _formatDate(rental.endDate),
                  isCancelling:
                  provider.cancellingRentalId ==
                      rental.id,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder:
                            (BuildContext context) {
                          return RentalDetailsScreen(
                            rental: rental,
                          );
                        },
                      ),
                    );
                  },
                  onCancel:
                  rental.status == 'PENDING' ||
                      rental.status ==
                          'CONFIRMED'
                      ? () {
                    _cancelRental(
                      provider,
                      rental,
                    );
                  }
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RentalsHeader extends StatelessWidget {
  final int totalRentals;
  final VoidCallback onHistoryPressed;

  const _RentalsHeader({
    required this.totalRentals,
    required this.onHistoryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        18,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderSoft,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'ACTIVE BOOKINGS',
                style: TextStyle(
                  color: AppTheme.primaryBlueDark,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Divider(
                  color: AppTheme.primaryYellowStrong,
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your rental journey.',
                      style: TextStyle(
                        color: AppTheme.darkColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalRentals booking(s) found',
                      style: const TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              OutlinedButton.icon(
                onPressed: onHistoryPressed,
                icon: const Icon(
                  Icons.history_rounded,
                  size: 17,
                ),
                label: const Text(
                  'HISTORY',
                  style: TextStyle(
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RentalCard extends StatelessWidget {
  final Rental rental;
  final _StatusStyle statusStyle;
  final String startDate;
  final String endDate;
  final bool isCancelling;
  final VoidCallback onTap;
  final VoidCallback? onCancel;

  const _RentalCard({
    required this.rental,
    required this.statusStyle,
    required this.startDate,
    required this.endDate,
    required this.isCancelling,
    required this.onTap,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(
          color: AppTheme.borderColor,
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12171717),
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            color: statusStyle.foreground,
          ),

          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color:
                          AppTheme.primaryYellow,
                          borderRadius:
                          BorderRadius.circular(
                            AppTheme.smallRadius,
                          ),
                        ),
                        child: const Icon(
                          Icons.car_rental_rounded,
                          color: AppTheme.primaryBlue,
                          size: 29,
                        ),
                      ),

                      const SizedBox(width: 13),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RENTAL #${rental.id}',
                              style: const TextStyle(
                                color: AppTheme
                                    .primaryBlueDark,
                                fontSize: 8,
                                fontWeight:
                                FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              rental.carName,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                color:
                                AppTheme.darkColor,
                                fontSize: 17,
                                fontWeight:
                                FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                          statusStyle.background,
                          borderRadius:
                          BorderRadius.circular(
                            AppTheme.smallRadius,
                          ),
                        ),
                        child: Text(
                          rental.status.replaceAll(
                            '_',
                            ' ',
                          ),
                          style: TextStyle(
                            color:
                            statusStyle.foreground,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppTheme.smallRadius,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DateValue(
                            label: 'PICKUP',
                            value: startDate,
                          ),
                        ),
                        const Padding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal: 9,
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: AppTheme.primaryBlue,
                            size: 18,
                          ),
                        ),
                        Expanded(
                          child: _DateValue(
                            label: 'RETURN',
                            value: endDate,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      const Text(
                        'TOTAL PRICE',
                        style: TextStyle(
                          color: AppTheme.mutedColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '\$${rental.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color:
                          AppTheme.primaryBlueDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppTheme.primaryBlue,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (onCancel != null) ...[
            const Divider(height: 1),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed:
                isCancelling ? null : onCancel,
                icon: isCancelling
                    ? const SizedBox(
                  width: 17,
                  height: 17,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                ),
                label: Text(
                  isCancelling
                      ? 'CANCELLING...'
                      : 'CANCEL RENTAL',
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                  AppTheme.errorDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateValue extends StatelessWidget {
  final String label;
  final String value;

  const _DateValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.mutedColor,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.darkColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onClose;

  const _ErrorBanner({
    required this.message,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.errorDark,
                fontSize: 10,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 14),
          Text(
            'LOADING RENTALS...',
            style: TextStyle(
              color: AppTheme.primaryBlueDark,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.cloud_off_outlined,
      title: 'Unable to load rentals',
      message: message,
      onPressed: onRetry,
      buttonText: 'TRY AGAIN',
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;

  const _EmptyState({
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredState(
      icon: Icons.receipt_long_outlined,
      title: 'No active rentals',
      message:
      'Your active rentals will appear here.',
      onPressed: onRefresh,
      buttonText: 'REFRESH',
    );
  }
}

class _CenteredState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onPressed;
  final String buttonText;

  const _CenteredState({
    required this.icon,
    required this.title,
    required this.message,
    required this.onPressed,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlueSoft,
                borderRadius: BorderRadius.circular(
                  AppTheme.largeRadius,
                ),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryBlue,
                size: 38,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.darkColor,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 19),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusStyle {
  final Color foreground;
  final Color background;

  const _StatusStyle({
    required this.foreground,
    required this.background,
  });
}