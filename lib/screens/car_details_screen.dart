import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/car.dart';
import '../theme/app_theme.dart';
import '../widgets/primary_button.dart';
import 'create_rental_screen.dart';

class CarDetailsScreen extends StatelessWidget {
  final Car car;

  const CarDetailsScreen({
    super.key,
    required this.car,
  });

  Future<void> _shareCar() async {
    await SharePlus.instance.share(
      ShareParams(
        subject: car.fullName,
        text:
        '${car.fullName} (${car.year})\n'
            'Category: ${car.category ?? 'Not specified'}\n'
            'Price: \$${car.pricePerDay.toStringAsFixed(2)} per day\n'
            'Status: ${car.status}',
      ),
    );
  }

  void _openRentalScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return CreateRentalScreen(car: car);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _StatusStyle statusStyle =
    _getStatusStyle(car.status);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(
              right: 14,
              top: 8,
              bottom: 8,
            ),
            child: IconButton(
              tooltip: 'Share vehicle',
              onPressed: _shareCar,
              icon: const Icon(
                Icons.share_outlined,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _DetailsGridPainter(),
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
                Row(
                  children: [
                    const Text(
                      'VEHICLE PROFILE',
                      style: TextStyle(
                        color: AppTheme.primaryBlueDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Divider(
                        color:
                        AppTheme.primaryYellowStrong,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '#${car.id.toString().padLeft(3, '0')}',
                      style: const TextStyle(
                        color: AppTheme.mutedColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                _VehicleCard(
                  car: car,
                  statusStyle: statusStyle,
                ),

                const SizedBox(height: 22),

                const Text(
                  'VEHICLE SPECIFICATIONS',
                  style: TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _SpecificationCard(
                        icon:
                        Icons.calendar_today_outlined,
                        label: 'MODEL YEAR',
                        value: car.year.toString(),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _SpecificationCard(
                        icon: Icons.category_outlined,
                        label: 'CATEGORY',
                        value:
                        car.category ?? 'Not specified',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 11),

                Row(
                  children: [
                    Expanded(
                      child: _SpecificationCard(
                        icon: Icons.pin_outlined,
                        label: 'PLATE NUMBER',
                        value: car.plateNumber,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: _SpecificationCard(
                        icon:
                        Icons.local_offer_outlined,
                        label: 'DAILY RATE',
                        value:
                        '\$${car.effectivePricePerDay.toStringAsFixed(2)}',
                        valueColor: car.hasDiscount
                            ? AppTheme.successColor
                            : AppTheme.primaryBlueDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                if (car.hasDiscount) ...[
                  _OfferNotice(car: car),
                  const SizedBox(height: 14),
                ],

                _AvailabilityNotice(
                  isAvailable: car.isAvailable,
                  isRentedNow: car.isRentedNow,
                ),

                const SizedBox(height: 22),

                PrimaryButton(
                  text: car.isBookable
                      ? 'RESERVE THIS VEHICLE  →'
                      : 'VEHICLE NOT AVAILABLE',
                  onPressed: car.isBookable
                      ? () {
                    _openRentalScreen(context);
                  }
                      : null,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _shareCar,
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'SHARE VEHICLE DETAILS',
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

  static _StatusStyle _getStatusStyle(
      String status,
      ) {
    switch (status) {
      case 'AVAILABLE':
        return const _StatusStyle(
          text: 'IN SERVICE',
          foreground: AppTheme.successColor,
          background: AppTheme.successSoft,
        );
      case 'MAINTENANCE':
        return const _StatusStyle(
          text: 'MAINTENANCE',
          foreground: AppTheme.errorDark,
          background: AppTheme.errorSoft,
        );
      default:
        return _StatusStyle(
          text: status.replaceAll('_', ' '),
          foreground: const Color(0xFF806900),
          background: AppTheme.primaryYellowSoft,
        );
    }
  }
}

class _VehicleCard extends StatelessWidget {
  final Car car;
  final _StatusStyle statusStyle;

  const _VehicleCard({
    required this.car,
    required this.statusStyle,
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
            color: Color(0x17171717),
            offset: Offset(6, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            color: AppTheme.primaryBlue,
          ),

          _VehicleImage(
            imageUrl: car.imageUrl,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              17,
              18,
              18,
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            (car.category ??
                                'UNCATEGORIZED')
                                .toUpperCase(),
                            style: const TextStyle(
                              color:
                              AppTheme.primaryBlueDark,
                              fontSize: 9,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: 1.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            car.fullName,
                            style: const TextStyle(
                              color:
                              AppTheme.darkColor,
                              fontSize: 25,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: -1.1,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: statusStyle.background,
                        borderRadius:
                        BorderRadius.circular(
                          AppTheme.smallRadius,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color:
                              statusStyle.foreground,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusStyle.text,
                            style: TextStyle(
                              color:
                              statusStyle.foreground,
                              fontSize: 8,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryYellowSoft,
                    border: Border.all(
                      color:
                      AppTheme.primaryYellowStrong,
                    ),
                    borderRadius: BorderRadius.circular(
                      AppTheme.defaultRadius,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppTheme.primaryBlue,
                        size: 25,
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Text(
                          'BASE DAILY RATE',
                          style: TextStyle(
                            color: AppTheme.darkSoft,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),

                      if (car.hasDiscount) ...[
                        Text(
                          '\$${car.pricePerDay.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.mutedColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      Text(
                        '\$${car.effectivePricePerDay.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: car.hasDiscount
                              ? AppTheme.successColor
                              : AppTheme.primaryBlueDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),

                      const SizedBox(width: 5),

                      const Text(
                        '/ DAY',
                        style: TextStyle(
                          color: AppTheme.mutedColor,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _VehicleImage extends StatelessWidget {
  final String? imageUrl;

  const _VehicleImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      height: 245,
      width: double.infinity,
      color: AppTheme.primaryBlueSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_rounded,
        color: AppTheme.primaryBlue,
        size: 94,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallback;
    }

    return Image.network(
      imageUrl!,
      height: 245,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (
          BuildContext context,
          Object error,
          StackTrace? stackTrace,
          ) {
        return fallback;
      },
      loadingBuilder: (
          BuildContext context,
          Widget child,
          ImageChunkEvent? progress,
          ) {
        if (progress == null) {
          return child;
        }

        return Container(
          height: 245,
          color: AppTheme.primaryBlueSoft,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
    );
  }
}

class _SpecificationCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _SpecificationCard({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppTheme.darkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 118,
      ),
      padding: const EdgeInsets.all(14),
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
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 23,
          ),

          const SizedBox(height: 14),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.mutedColor,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityNotice extends StatelessWidget {
  final bool isAvailable;
  final bool isRentedNow;

  const _AvailabilityNotice({
    required this.isAvailable,
    required this.isRentedNow,
  });

  @override
  Widget build(BuildContext context) {
    // Three cases: free now, rented now (future dates still open),
    // or in maintenance (no booking at all).
    final Color foreground;
    final Color background;
    final IconData icon;
    final String title;
    final String message;

    if (isAvailable) {
      foreground = AppTheme.successColor;
      background = AppTheme.successSoft;
      icon = Icons.verified_outlined;
      title = 'AVAILABLE TO RESERVE';
      message = 'Select your rental dates to continue.';
    } else if (isRentedNow) {
      foreground = AppTheme.primaryBlueDark;
      background = AppTheme.primaryBlueSoft;
      icon = Icons.event_repeat_outlined;
      title = 'ON A RENTAL RIGHT NOW';
      message = 'You can still book it for dates after it comes back. '
          'Taken days are greyed out in the calendar.';
    } else {
      foreground = AppTheme.errorDark;
      background = AppTheme.errorSoft;
      icon = Icons.build_outlined;
      title = 'IN MAINTENANCE';
      message = 'This vehicle cannot be reserved right now.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(
          color: foreground.withValues(alpha: 0.35),
        ),
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: foreground, size: 24),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 10,
                    height: 1.4,
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

class _StatusStyle {
  final String text;
  final Color foreground;
  final Color background;

  const _StatusStyle({
    required this.text,
    required this.foreground,
    required this.background,
  });
}

class _DetailsGridPainter extends CustomPainter {
  const _DetailsGridPainter();

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
      covariant _DetailsGridPainter oldDelegate,
      ) {
    return false;
  }
}


// Green banner that explains today's offer on this car.
class _OfferNotice extends StatelessWidget {
  final Car car;

  const _OfferNotice({required this.car});

  @override
  Widget build(BuildContext context) {
    final String percentage =
        car.offerPercentage?.toStringAsFixed(0) ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.successSoft,
        border: Border.all(color: AppTheme.successColor),
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_offer_outlined,
            color: AppTheme.successColor,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$percentage% off today',
                  style: const TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  car.offerEndDate == null
                      ? (car.offerName ?? 'Limited time offer')
                      : '${car.offerName ?? 'Offer'} · ends ${car.offerEndDate}',
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 12,
                    height: 1.4,
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
