import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../providers/car_provider.dart';
import '../screens/car_details_screen.dart';
import '../screens/car_form_screen.dart';
import '../services/car_service.dart';
import '../theme/app_theme.dart';
import '../utils/car_photo_uploader.dart';

class CarsCatalog extends StatefulWidget {
  final bool isAdmin;

  const CarsCatalog({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<CarsCatalog> createState() {
    return _CarsCatalogState();
  }
}

class _CarsCatalogState extends State<CarsCatalog> {
  late final TextEditingController _searchController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    final CarsProvider provider =
    context.read<CarsProvider>();

    _searchController = TextEditingController(
      text: provider.searchQuery,
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.cars.isEmpty) {
        provider.loadCars();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Load the next page before the user reaches the very bottom,
  // so the list feels endless instead of asking for a button tap.
  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final double distanceToBottom =
        _scrollController.position.maxScrollExtent -
            _scrollController.position.pixels;

    if (distanceToBottom > 400) {
      return;
    }

    final CarsProvider provider = context.read<CarsProvider>();

    // The provider ignores the call when it is already loading
    // or when there is nothing left to load.
    if (provider.hasMore &&
        !provider.isLoadingMore &&
        !provider.isLoading) {
      provider.loadMoreCars();
    }
  }

  Future<void> _clearAllFilters(
      CarsProvider provider,
      ) async {
    _searchController.clear();
    await provider.clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final CarsProvider provider =
    context.watch<CarsProvider>();

    return Column(
      children: [
        _SearchSection(
          controller: _searchController,
          provider: provider,
          onClearAll: () {
            _clearAllFilters(provider);
          },
        ),

        if (provider.isLoading &&
            provider.cars.isNotEmpty)
          const LinearProgressIndicator(
            minHeight: 3,
          ),

        if (provider.errorMessage != null &&
            provider.cars.isNotEmpty)
          _ErrorBanner(
            message: provider.errorMessage!,
            onClose: provider.clearError,
          ),

        Expanded(
          child: _buildContent(provider),
        ),
      ],
    );
  }

  Widget _buildContent(CarsProvider provider) {
    if (provider.isLoading &&
        provider.cars.isEmpty) {
      return const _LoadingState();
    }

    if (provider.errorMessage != null &&
        provider.cars.isEmpty) {
      return _ErrorState(
        message: provider.errorMessage!,
        onRetry: provider.loadCars,
      );
    }

    if (provider.isEmpty) {
      return _EmptyState(
        hasFilters: provider.hasActiveFilters,
        onRefresh: provider.loadCars,
        onClearFilters: () {
          _clearAllFilters(provider);
        },
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: provider.refreshCars,
      child: ListView.separated(
        controller: _scrollController,
        physics:
        const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          28,
        ),
        itemCount: provider.cars.length +
            (provider.hasMore ||
                provider.isLoadingMore
                ? 1
                : 0),
        separatorBuilder: (
            BuildContext context,
            int index,
            ) {
          return const SizedBox(height: 16);
        },
        itemBuilder: (
            BuildContext context,
            int index,
            ) {
          if (index == provider.cars.length) {
            return _LoadMoreFooter(
              isLoading: provider.isLoadingMore,
              onPressed: provider.loadMoreCars,
            );
          }

          return _EntranceAnimation(
            // Keyed by the car, so a card animates once when it appears,
            // not every time the list rebuilds.
            key: ValueKey<int>(provider.cars[index].id),
            // Cards from the first page come in one after another;
            // cards from "load more" appear almost at once.
            delay: Duration(milliseconds: 70 * (index % 10).clamp(0, 6)),
            child: _CarCard(
              car: provider.cars[index],
              unitNumber: index + 1,
              isAdmin: widget.isAdmin,
            ),
          );
        },
      ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  final TextEditingController controller;
  final CarsProvider provider;
  final VoidCallback onClearAll;

  const _SearchSection({
    required this.controller,
    required this.provider,
    required this.onClearAll,
  });

  static const List<String> _statuses = [
    'AVAILABLE',
    'RENTED',
    'MAINTENANCE',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.cardColor,
      padding: const EdgeInsets.fromLTRB(
        16,
        15,
        16,
        13,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: provider.updateSearchQuery,
            decoration: InputDecoration(
              hintText:
              'Search brand, model or plate...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: provider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  provider.updateSearchQuery('');
                },
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'VEHICLE STATUS',
            style: TextStyle(
              color: AppTheme.darkSoft,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
            ),
          ),

          const SizedBox(height: 9),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatusChip(
                  label: 'All',
                  selected:
                  provider.selectedStatus == null,
                  onSelected: () {
                    provider.updateStatus(null);
                  },
                ),

                const SizedBox(width: 8),

                ..._statuses.map((String status) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(right: 8),
                    child: _StatusChip(
                      label: _formatStatus(status),
                      selected:
                      provider.selectedStatus ==
                          status,
                      onSelected: () {
                        provider.updateStatus(status);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlueSoft,
                  borderRadius: BorderRadius.circular(
                    AppTheme.smallRadius,
                  ),
                ),
                child: Text(
                  '${provider.totalCars} VEHICLES',
                  style: const TextStyle(
                    color: AppTheme.primaryBlueDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),

              const Spacer(),

              if (provider.hasActiveFilters)
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(
                    Icons.filter_alt_off_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'CLEAR',
                    style: TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatStatus(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'Available';
      case 'RENTED':
        return 'Rented';
      case 'MAINTENANCE':
        return 'Maintenance';
      default:
        return status;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      avatar: selected
          ? const Icon(
        Icons.check_rounded,
        size: 15,
        color: AppTheme.primaryBlueDark,
      )
          : null,
      backgroundColor: AppTheme.cardColor,
      selectedColor: AppTheme.primaryYellow,
      side: BorderSide(
        color: selected
            ? AppTheme.primaryYellowStrong
            : AppTheme.borderColor,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          AppTheme.smallRadius,
        ),
      ),
      labelStyle: TextStyle(
        color: selected
            ? AppTheme.darkColor
            : AppTheme.textColor,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      onSelected: (bool value) {
        onSelected();
      },
    );
  }
}

class _CarCard extends StatelessWidget {
  final Car car;
  final int unitNumber;
  final bool isAdmin;

  const _CarCard({
    required this.car,
    required this.unitNumber,
    this.isAdmin = false,
  });

  // "Ends today", "1 day left", "5 days left" from the offer's end date.
  static String? _offerTimeLeft(String? endDate) {
    if (endDate == null) {
      return null;
    }

    final DateTime? end = DateTime.tryParse(endDate);

    if (end == null) {
      return null;
    }

    final DateTime today = DateUtils.dateOnly(DateTime.now());
    final int days = DateUtils.dateOnly(end).difference(today).inDays;

    if (days < 0) {
      return null;
    }

    if (days == 0) {
      return 'ENDS TODAY';
    }

    return days == 1 ? '1 DAY LEFT' : '$days DAYS LEFT';
  }

  Future<void> _addPhotos(BuildContext context) async {
    final bool uploaded = await pickAndUploadCarPhotos(
      context,
      carId: car.id,
      carName: car.fullName,
    );

    if (uploaded && context.mounted) {
      await context.read<CarsProvider>().refreshCars();
    }
  }

  Future<void> _editCar(BuildContext context) async {
    final bool? saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => CarFormScreen(car: car),
      ),
    );

    if (saved == true && context.mounted) {
      await context.read<CarsProvider>().refreshCars();
    }
  }

  Future<void> _deleteCar(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete car'),
          content: Text(
            'Delete ${car.fullName} (${car.plateNumber})?\n'
                'This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorColor,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final CarsProvider provider = context.read<CarsProvider>();

    try {
      await CarService().deleteCar(car.id);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Car deleted.'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      await provider.refreshCars();
    } on CarServiceException catch (error) {
      // For example: a car with rental history cannot be deleted.
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _openDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return CarDetailsScreen(car: car);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _StatusStyle statusStyle =
    _statusStyle(car.status);

    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(
        AppTheme.defaultRadius,
      ),
      child: InkWell(
        onTap: () {
          _openDetails(context);
        },
        borderRadius: BorderRadius.circular(
          AppTheme.defaultRadius,
        ),
        child: Container(
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
                color: Color(0x14171717),
                offset: Offset(5, 5),
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
                color: car.isAvailable
                    ? AppTheme.primaryBlue
                    : AppTheme.primaryYellow,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  13,
                  15,
                  12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'UNIT ${unitNumber.toString().padLeft(3, '0')}'
                                ' · '
                                '${(car.category ?? 'UNCATEGORIZED').toUpperCase()}',
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                              AppTheme.mutedColor,
                              fontSize: 9,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            car.fullName,
                            maxLines: 1,
                            overflow:
                            TextOverflow.ellipsis,
                            style: const TextStyle(
                              color:
                              AppTheme.darkColor,
                              fontSize: 20,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
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
                              color: statusStyle.foreground,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _statusText(car.status),
                            style: TextStyle(
                              color:
                              statusStyle.foreground,
                              fontSize: 9,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit and delete, for the Admin only.
                    if (isAdmin)
                      PopupMenuButton<String>(
                        tooltip: 'Car actions',
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppTheme.darkSoft,
                        ),
                        onSelected: (String action) {
                          if (action == 'photos') {
                            _addPhotos(context);
                          } else if (action == 'edit') {
                            _editCar(context);
                          } else if (action == 'delete') {
                            _deleteCar(context);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem<String>(
                            value: 'photos',
                            child: ListTile(
                              leading: Icon(Icons.add_a_photo_outlined),
                              title: Text('Add photos'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                                color: AppTheme.errorColor,
                              ),
                              title: Text(
                                'Delete',
                                style: TextStyle(
                                  color: AppTheme.errorColor,
                                ),
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              Stack(
                children: [
                  _CarImage(
                    imageUrl: car.imageUrl,
                  ),

                  // Today's offer, so the customer sees it
                  // without opening the car.
                  if (car.hasDiscount)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
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
                              '${car.offerPercentage?.toStringAsFixed(0) ?? ''}% OFF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_offerTimeLeft(car.offerEndDate) != null) ...[
                              Container(
                                width: 1,
                                height: 11,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                ),
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                              Text(
                                _offerTimeLeft(car.offerEndDate)!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              Container(
                color: const Color(0xFFF0F0F0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.darkColor,
                        borderRadius:
                        BorderRadius.circular(4),
                      ),
                      child: Text(
                        car.plateNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    const Text(
                      'MODEL YEAR',
                      style: TextStyle(
                        color: AppTheme.mutedColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(width: 7),

                    Text(
                      car.year.toString(),
                      style: const TextStyle(
                        color: AppTheme.darkSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  15,
                  14,
                  12,
                  14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            car.hasDiscount
                                ? 'TODAY\'S RATE'
                                : 'BASE DAILY RATE',
                            style: const TextStyle(
                              color:
                              AppTheme.mutedColor,
                              fontSize: 8,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${car.effectivePricePerDay.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: car.hasDiscount
                                      ? AppTheme.successColor
                                      : AppTheme.primaryBlueDark,
                                  fontSize: 23,
                                  fontWeight:
                                  FontWeight.w700,
                                  letterSpacing: -1,
                                ),
                              ),

                              if (car.hasDiscount) ...[
                                const SizedBox(width: 8),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    '\$${car.pricePerDay.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: AppTheme.mutedColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration:
                                      TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),

                    OutlinedButton(
                      onPressed: () {
                        _openDetails(context);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding:
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                        ),
                      ),
                      child: const Text(
                        'DETAILS  →',
                        style: TextStyle(
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static _StatusStyle _statusStyle(
      String status,
      ) {
    switch (status) {
      case 'AVAILABLE':
        return const _StatusStyle(
          foreground: AppTheme.successColor,
          background: AppTheme.successSoft,
        );
      case 'MAINTENANCE':
        return const _StatusStyle(
          foreground: AppTheme.errorDark,
          background: AppTheme.errorSoft,
        );
      default:
        return const _StatusStyle(
          foreground: Color(0xFF806900),
          background: AppTheme.primaryYellowSoft,
        );
    }
  }

  static String _statusText(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'IN SERVICE';
      case 'MAINTENANCE':
        return 'MAINTENANCE';
      case 'RENTED':
        return 'RENTED';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}

class _CarImage extends StatelessWidget {
  final String? imageUrl;

  const _CarImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      height: 205,
      width: double.infinity,
      color: AppTheme.primaryBlueSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_rounded,
        size: 72,
        color: AppTheme.primaryBlue,
      ),
    );

    if (imageUrl == null || imageUrl!.isEmpty) {
      return fallback;
    }

    return Image.network(
      imageUrl!,
      height: 205,
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
          height: 205,
          color: AppTheme.primaryBlueSoft,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
    );
  }
}

/*
 * Grey placeholder cards shaped like the real ones,
 * with a light shimmer moving across them.
 * The list feels faster than a spinning circle.
 */
class _LoadingState extends StatefulWidget {
  const _LoadingState();

  @override
  State<_LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<_LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            return _SkeletonCard(progress: _shimmer.value);
          },
        );
      },
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double progress;

  const _SkeletonCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    // The bright band slides from left to right.
    final Gradient shimmer = LinearGradient(
      begin: Alignment(-1.5 + progress * 3, 0),
      end: Alignment(-0.5 + progress * 3, 0),
      colors: const [
        Color(0xFFEDEDED),
        Color(0xFFF8F8F8),
        Color(0xFFEDEDED),
      ],
    );

    Widget block({double? width, required double height, double radius = 6}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: shimmer,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border.all(color: AppTheme.borderSoft),
        borderRadius: BorderRadius.circular(AppTheme.defaultRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(width: 110, height: 9),
                const SizedBox(height: 12),
                block(width: 190, height: 18),
              ],
            ),
          ),
          block(height: 150, radius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(width: 70, height: 8),
                      const SizedBox(height: 10),
                      block(width: 100, height: 20),
                    ],
                  ),
                ),
                block(width: 96, height: 40, radius: AppTheme.defaultRadius),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/*
 * Fades a card in while it slides up a little.
 * Used so the first cards appear one after another.
 */
class _EntranceAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _EntranceAnimation({
    super.key,
    required this.child,
    required this.delay,
  });

  @override
  State<_EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<_EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
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
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        0,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorSoft,
        border: Border.all(
          color: AppTheme.errorColor,
        ),
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
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageState(
      icon: Icons.cloud_off_outlined,
      iconColor: AppTheme.errorDark,
      iconBackground: AppTheme.errorSoft,
      title: 'Unable to load fleet',
      message: message,
      buttonLabel: 'TRY AGAIN',
      buttonIcon: Icons.refresh_rounded,
      onPressed: onRetry,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onRefresh;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilters,
    required this.onRefresh,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageState(
      icon: Icons.directions_car_outlined,
      iconColor: AppTheme.primaryBlue,
      iconBackground: AppTheme.primaryBlueSoft,
      title: hasFilters
          ? 'No matching vehicles'
          : 'No vehicles available',
      message: hasFilters
          ? 'Try changing your search or selected status.'
          : 'There are no vehicles to display right now.',
      buttonLabel:
      hasFilters ? 'CLEAR FILTERS' : 'REFRESH',
      buttonIcon: hasFilters
          ? Icons.filter_alt_off_rounded
          : Icons.refresh_rounded,
      onPressed:
      hasFilters ? onClearFilters : onRefresh,
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String message;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onPressed;

  const _MessageState({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.buttonIcon,
    required this.onPressed,
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
                color: iconBackground,
                borderRadius: BorderRadius.circular(
                  AppTheme.largeRadius,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

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
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonLabel),
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


// Shown at the end of the list while the next page loads.
// The button stays as a fallback if the automatic load fails.
class _LoadMoreFooter extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoadMoreFooter({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: TextButton(
          onPressed: onPressed,
          child: const Text('LOAD MORE'),
        ),
      ),
    );
  }
}
