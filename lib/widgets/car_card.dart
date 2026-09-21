import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/car.dart';

class CarCard extends StatefulWidget {
  final Car car;
  final VoidCallback onTap;
  final VoidCallback? onRent;
  final bool showFavorite;

  const CarCard({
    super.key,
    required this.car,
    required this.onTap,
    this.onRent,
    this.showFavorite = true,
  });

  @override
  State<CarCard> createState() =>
      _CarCardState();
}

class _CarCardState extends State<CarCard> {
  bool _isFavorite = false;
  bool _isRentSuccess = false;

  static const Color _dark =
  Color(0xFF202124);

  static const Color _gold =
  Color(0xFFC6922E);

  void _toggleFavorite() {
    HapticFeedback.selectionClick();

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _rentCar() async {
    if (widget.onRent == null ||
        _isRentSuccess) {
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isRentSuccess = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 450),
    );

    if (!mounted) {
      return;
    }

    widget.onRent!();

    setState(() {
      _isRentSuccess = false;
    });
  }

  Color _statusColor() {
    switch (widget.car.status) {
      case 'AVAILABLE':
        return const Color(0xFF18864B);

      case 'RENTED':
        return const Color(0xFFD97706);

      case 'MAINTENANCE':
        return const Color(0xFFDC2626);

      default:
        return Colors.grey;
    }
  }

  String _statusText() {
    switch (widget.car.status) {
      case 'AVAILABLE':
        return 'Available';

      case 'RENTED':
        return 'Rented';

      case 'MAINTENANCE':
        return 'Maintenance';

      default:
        return widget.car.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
    _statusColor();

    return Semantics(
      button: true,
      label: widget.car.fullName,
      hint: 'Open car details',
      child: Card(
        margin: EdgeInsets.zero,
        color: Colors.white,
        elevation: 4,
        shadowColor:
        Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: _CarNetworkImage(
                        imageUrl:
                        widget.car.imageUrl,
                        semanticLabel:
                        widget.car.fullName,
                      ),
                    ),

                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.94,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          _statusText(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    // Offer ribbon, same idea as the website.
                    if (widget.car.hasDiscount)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF18864B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer_outlined,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.car.offerPercentage?.toStringAsFixed(0) ?? ''}% OFF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (widget.showFavorite)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Semantics(
                          button: true,
                          label: _isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          child: Material(
                            color: Colors.white
                                .withValues(
                              alpha: 0.94,
                            ),
                            shape:
                            const CircleBorder(),
                            elevation: 1,
                            child: InkWell(
                              customBorder:
                              const CircleBorder(),
                              onTap:
                              _toggleFavorite,
                              child:
                              AnimatedContainer(
                                duration:
                                const Duration(
                                  milliseconds: 220,
                                ),
                                width: 38,
                                height: 38,
                                child:
                                AnimatedSwitcher(
                                  duration:
                                  const Duration(
                                    milliseconds:
                                    220,
                                  ),
                                  transitionBuilder:
                                      (
                                      child,
                                      animation,
                                      ) {
                                    return ScaleTransition(
                                      scale:
                                      animation,
                                      child: child,
                                    );
                                  },
                                  child: Icon(
                                    _isFavorite
                                        ? Icons
                                        .favorite_rounded
                                        : Icons
                                        .favorite_border_rounded,
                                    key: ValueKey(
                                      _isFavorite,
                                    ),
                                    color: _isFavorite
                                        ? Colors.red
                                        : _dark,
                                    size: 21,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                Semantics(
                  header: true,
                  label: widget.car.fullName,
                  child: Text(
                    widget.car.fullName,
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF2D3436),
                      fontSize: 16,
                      height: 1.25,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  '${widget.car.year}'
                      '  •  '
                      '${widget.car.category ?? 'Uncategorized'}',
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF636E72),
                    fontSize: 12,
                  ),
                ),

                const Spacer(),

                // When an offer is running today, the old price is
                // crossed out above the new one.
                if (widget.car.hasDiscount)
                  Text(
                    '\$${widget.car.pricePerDay.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF8A94A6),
                      fontSize: 12,
                      decoration:
                      TextDecoration.lineThrough,
                    ),
                  ),

                Semantics(
                  label:
                  '${widget.car.effectivePricePerDay.toStringAsFixed(2)} dollars per day',
                  child: Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          '\$${widget.car.effectivePricePerDay.toStringAsFixed(2)}',
                          overflow:
                          TextOverflow
                              .ellipsis,
                          style: TextStyle(
                            color: widget.car.hasDiscount
                                ? const Color(0xFF18864B)
                                : _gold,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding:
                        EdgeInsets.only(
                          bottom: 2,
                        ),
                        child: Text(
                          '/ day',
                          style: TextStyle(
                            color:
                            Color(0xFF636E72),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: widget.onRent == null
                      ? OutlinedButton(
                    onPressed:
                    widget.onTap,
                    style: OutlinedButton
                        .styleFrom(
                      foregroundColor:
                      _dark,
                      side:
                      const BorderSide(
                        color: _dark,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  )
                      : ElevatedButton(
                    onPressed:
                    widget.car.isAvailable
                        ? _rentCar
                        : null,
                    style: ElevatedButton
                        .styleFrom(
                      backgroundColor:
                      _dark,
                      foregroundColor:
                      Colors.white,
                      disabledBackgroundColor:
                      const Color(
                        0xFFE5E7EB,
                      ),
                      disabledForegroundColor:
                      const Color(
                        0xFF858B91,
                      ),
                      elevation: 0,
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius
                            .circular(10),
                      ),
                    ),
                    child:
                    AnimatedSwitcher(
                      duration:
                      const Duration(
                        milliseconds: 250,
                      ),
                      child: _isRentSuccess
                          ? const Row(
                        key: ValueKey(
                          'success',
                        ),
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Icon(
                            Icons
                                .check_circle_outline,
                            size: 20,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(
                            'Ready',
                            style:
                            TextStyle(
                              fontWeight:
                              FontWeight
                                  .w700,
                            ),
                          ),
                        ],
                      )
                          : Text(
                        key:
                        const ValueKey(
                          'button',
                        ),
                        widget.car
                            .isAvailable
                            ? 'Rent Now'
                            : 'Unavailable',
                        style:
                        const TextStyle(
                          fontWeight:
                          FontWeight
                              .w700,
                        ),
                      ),
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

class _CarNetworkImage
    extends StatelessWidget {
  final String? imageUrl;
  final String semanticLabel;

  const _CarNetworkImage({
    required this.imageUrl,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      color: const Color(0xFFF1F2F4),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_rounded,
        size: 58,
        color: Color(0xFF8B9096),
      ),
    );

    return ClipRRect(
      borderRadius:
      BorderRadius.circular(10),
      child: imageUrl == null ||
          imageUrl!.trim().isEmpty
          ? fallback
          : Image.network(
        imageUrl!,
        semanticLabel: semanticLabel,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (
            context,
            child,
            loadingProgress,
            ) {
          if (loadingProgress == null) {
            return child;
          }

          return const _ShimmerPlaceholder();
        },
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return fallback;
        },
      ),
    );
  }
}

class _ShimmerPlaceholder
    extends StatefulWidget {
  const _ShimmerPlaceholder();

  @override
  State<_ShimmerPlaceholder> createState() =>
      _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState
    extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration:
      const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(
                -1.5 + (_controller.value * 3),
                0,
              ),
              end: Alignment(
                -0.5 + (_controller.value * 3),
                0,
              ),
              colors: const [
                Color(0xFFE9EAEC),
                Color(0xFFF7F7F8),
                Color(0xFFE9EAEC),
              ],
            ),
          ),
        );
      },
    );
  }
}