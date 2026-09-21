import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../models/create_rental_request.dart';
import '../models/create_rental_response.dart';
import '../providers/rental_provider.dart';
import '../services/rental_service.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';

class CreateRentalScreen extends StatefulWidget {
  final Car car;

  const CreateRentalScreen({
    super.key,
    required this.car,
  });

  @override
  State<CreateRentalScreen> createState() {
    return _CreateRentalScreenState();
  }
}

class _CreateRentalScreenState
    extends State<CreateRentalScreen> {
  final RentalService _rentalService = RentalService();

  DateTime? _startDate;
  DateTime? _endDate;

  RentalQuote? _quote;
  bool _isLoadingQuote = false;
  int _quoteRequestId = 0;

  // The server is the source of truth for the price,
  // so its quote wins over the local estimate.
  double get _displayedPrice {
    return _quote?.totalPrice ?? _estimatedPrice;
  }

  Future<void> _loadQuote() async {
    if (_startDate == null || _endDate == null) {
      return;
    }

    final int requestId = ++_quoteRequestId;

    setState(() {
      _isLoadingQuote = true;
    });

    try {
      final RentalQuote quote = await _rentalService.getQuote(
        carId: widget.car.id,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (!mounted || requestId != _quoteRequestId) {
        return;
      }

      setState(() {
        _quote = quote;
        _isLoadingQuote = false;
      });
    } on RentalServiceException {
      if (!mounted || requestId != _quoteRequestId) {
        return;
      }

      // If the quote fails, keep showing the local estimate.
      setState(() {
        _quote = null;
        _isLoadingQuote = false;
      });
    }
  }

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
      helpText: 'SELECT PICKUP DATE',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _startDate = selectedDate;
      _quote = null;

      if (_endDate != null &&
          _endDate!.isBefore(selectedDate)) {
        _endDate = null;
      }
    });

    _loadQuote();
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
      helpText: 'SELECT RETURN DATE',
      cancelText: 'CANCEL',
      confirmText: 'SELECT',
    );

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _endDate = selectedDate;
      _quote = null;
    });

    _loadQuote();
  }

  Future<void> _confirmRental() async {
    if (!widget.car.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This car is not currently available.',
          ),
          backgroundColor: AppTheme.errorColor,
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
          backgroundColor: AppTheme.errorColor,
        ),
      );

      return;
    }

    final bool? confirmed =
    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppTheme.primaryYellow,
              borderRadius: BorderRadius.circular(
                AppTheme.defaultRadius,
              ),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: AppTheme.primaryBlue,
              size: 30,
            ),
          ),
          title: const Text(
            'Confirm Rental',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.car.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.darkColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              _DialogRow(
                title: 'Rental days',
                value: '$_rentalDays',
              ),
              const SizedBox(height: 10),
              _DialogRow(
                title: 'Estimated price',
                value:
                '\$${_displayedPrice.toStringAsFixed(2)}',
              ),
              const SizedBox(height: 16),
              const Text(
                'The backend will calculate the final price and applicable discounts.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.mutedColor,
                  fontSize: 10,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('CONFIRM'),
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
          backgroundColor: AppTheme.errorColor,
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
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.successSoft,
              borderRadius: BorderRadius.circular(
                AppTheme.defaultRadius,
              ),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppTheme.successColor,
              size: 38,
            ),
          ),
          title: const Text(
            'Rental Created',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ResultRow(
                title: 'RENTAL ID',
                value: '#${response.id}',
              ),
              const SizedBox(height: 11),
              _ResultRow(
                title: 'FINAL PRICE',
                value:
                '\$${response.totalPrice.toStringAsFixed(2)}',
                valueColor:
                AppTheme.primaryBlueDark,
              ),
              const SizedBox(height: 11),
              _ResultRow(
                title: 'STATUS',
                value: response.status,
                valueColor:
                AppTheme.successColor,
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('DONE'),
              ),
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
        title: const Text('Reserve Vehicle'),
      ),
      body: IgnorePointer(
        ignoring: provider.isCreating,
        child: Stack(
          children: [
            const Positioned.fill(
              child: CustomPaint(
                painter: _RentalGridPainter(),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                34,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'NEW RESERVATION',
                        style: TextStyle(
                          color:
                          AppTheme.primaryBlueDark,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Divider(
                          color: AppTheme
                              .primaryYellowStrong,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _VehicleSummary(
                    car: widget.car,
                  ),

                  const SizedBox(height: 24),

                  const _SectionHeading(
                    number: '01',
                    title: 'SELECT RENTAL PERIOD',
                    description:
                    'Choose the pickup and return dates.',
                  ),

                  const SizedBox(height: 14),

                  _DateField(
                    label: 'PICKUP DATE',
                    value: _formatDate(_startDate),
                    icon:
                    Icons.calendar_today_outlined,
                    selected: _startDate != null,
                    onTap: _selectStartDate,
                  ),

                  const SizedBox(height: 12),

                  _DateField(
                    label: 'RETURN DATE',
                    value: _formatDate(_endDate),
                    icon:
                    Icons.event_available_outlined,
                    selected: _endDate != null,
                    onTap: _selectEndDate,
                  ),

                  const SizedBox(height: 24),

                  const _SectionHeading(
                    number: '02',
                    title: 'PRICE SUMMARY',
                    description:
                    'Final price calculated by the server.',
                  ),

                  const SizedBox(height: 14),

                  _PriceSummary(
                    rentalDays: _rentalDays,
                    pricePerDay:
                    widget.car.pricePerDay,
                    estimatedPrice: _displayedPrice,
                    isLoadingQuote: _isLoadingQuote,
                    quote: _quote,
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    text: 'CONFIRM RENTAL  →',
                    isLoading: provider.isCreating,
                    onPressed: _confirmRental,
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

class _VehicleSummary extends StatelessWidget {
  final Car car;

  const _VehicleSummary({
    required this.car,
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
          AppTheme.largeRadius,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14171717),
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            color: AppTheme.primaryBlue,
          ),

          if (car.imageUrl != null &&
              car.imageUrl!.isNotEmpty)
            Image.network(
              car.imageUrl!,
              height: 155,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                return const _VehicleFallback();
              },
            )
          else
            const _VehicleFallback(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        (car.category ?? 'VEHICLE')
                            .toUpperCase(),
                        style: const TextStyle(
                          color:
                          AppTheme.primaryBlueDark,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        car.fullName,
                        style: const TextStyle(
                          color: AppTheme.darkColor,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${car.year} · ${car.plateNumber}',
                        style: const TextStyle(
                          color: AppTheme.mutedColor,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${car.pricePerDay.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color:
                        AppTheme.primaryBlueDark,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Text(
                      'PER DAY',
                      style: TextStyle(
                        color: AppTheme.mutedColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleFallback extends StatelessWidget {
  const _VehicleFallback();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 155,
      width: double.infinity,
      child: ColoredBox(
        color: AppTheme.primaryBlueSoft,
        child: Icon(
          Icons.directions_car_filled_rounded,
          color: AppTheme.primaryBlue,
          size: 70,
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _SectionHeading({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.primaryYellow,
            borderRadius: BorderRadius.circular(
              AppTheme.smallRadius,
            ),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppTheme.darkColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(width: 11),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.darkColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: AppTheme.mutedColor,
                  fontSize: 10,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(
        AppTheme.defaultRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? AppTheme.primaryBlue
                  : AppTheme.borderColor,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(
              AppTheme.defaultRadius,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryYellow
                      : AppTheme.primaryBlueSoft,
                  borderRadius: BorderRadius.circular(
                    AppTheme.smallRadius,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryBlue,
                  size: 22,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.mutedColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: TextStyle(
                        color: selected
                            ? AppTheme.darkColor
                            : AppTheme.mutedColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final int rentalDays;
  final double pricePerDay;
  final double estimatedPrice;
  final bool isLoadingQuote;
  final RentalQuote? quote;

  const _PriceSummary({
    required this.rentalDays,
    required this.pricePerDay,
    required this.estimatedPrice,
    this.isLoadingQuote = false,
    this.quote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
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
            color: Color(0x10171717),
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _PriceRow(
            title: 'RENTAL DAYS',
            value: '$rentalDays',
          ),

          const SizedBox(height: 12),

          _PriceRow(
            title: 'PRICE PER DAY',
            value:
            '\$${pricePerDay.toStringAsFixed(2)}',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 15,
            ),
            child: Divider(),
          ),

          if (quote != null && quote!.adjustmentAmount != 0) ...[
            _PriceRow(
              title: 'BASE TOTAL',
              value:
              '\$${quote!.baseTotal.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 12),

            _PriceRow(
              title: quote!.hasDiscount ? 'DISCOUNT' : 'SURCHARGE',
              value:
              '\$${quote!.adjustmentAmount.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 12),
          ],

          _PriceRow(
            title: isLoadingQuote
                ? 'CALCULATING...'
                : (quote != null ? 'TOTAL PRICE' : 'ESTIMATED BASE PRICE'),
            value:
            '\$${estimatedPrice.toStringAsFixed(2)}',
            isTotal: true,
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlueSoft,
              borderRadius: BorderRadius.circular(
                AppTheme.smallRadius,
              ),
            ),
            child: const Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Final price and discounts are calculated securely by the backend.',
                    style: TextStyle(
                      color:
                      AppTheme.primaryBlueDark,
                      fontSize: 9,
                      height: 1.45,
                    ),
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
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isTotal
                  ? AppTheme.darkColor
                  : AppTheme.textColor,
              fontSize: isTotal ? 10 : 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal
                ? AppTheme.primaryBlueDark
                : AppTheme.darkColor,
            fontSize: isTotal ? 21 : 14,
            fontWeight: FontWeight.w700,
            letterSpacing: isTotal ? -0.8 : 0,
          ),
        ),
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  final String title;
  final String value;

  const _DialogRow({
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
              color: AppTheme.mutedColor,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          value,
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

class _ResultRow extends StatelessWidget {
  final String title;
  final String value;
  final Color valueColor;

  const _ResultRow({
    required this.title,
    required this.value,
    this.valueColor = AppTheme.darkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(
          AppTheme.smallRadius,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.mutedColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RentalGridPainter extends CustomPainter {
  const _RentalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = AppTheme.borderSoft.withValues(
        alpha: 0.45,
      )
      ..strokeWidth = 0.7;

    const double gridSize = 44;

    for (
    double x = 0;
    x <= size.width;
    x += gridSize
    ) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (
    double y = 0;
    y <= size.height;
    y += gridSize
    ) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _RentalGridPainter oldDelegate,
      ) {
    return false;
  }
}