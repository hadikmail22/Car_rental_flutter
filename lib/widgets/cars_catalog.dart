import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../providers/car_provider.dart';
import '../screens/car_details_screen.dart';
import '../theme/app_theme.dart';

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

  @override
  void initState() {
    super.initState();

    final CarsProvider provider =
    context.read<CarsProvider>();

    _searchController = TextEditingController(
      text: provider.searchQuery,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (provider.cars.isEmpty) {
        provider.loadCars();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            return _LoadMoreButton(
              isLoading: provider.isLoadingMore,
              onPressed: provider.loadMoreCars,
            );
          }

          return _CarCard(
            car: provider.cars[index],
            unitNumber: index + 1,
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

  const _CarCard({
    required this.car,
    required this.unitNumber,
  });

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
                  ],
                ),
              ),

              _CarImage(
                imageUrl: car.imageUrl,
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
                          const Text(
                            'BASE DAILY RATE',
                            style: TextStyle(
                              color:
                              AppTheme.mutedColor,
                              fontSize: 8,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),

                          const SizedBox(height: 5),

                          Text(
                            '\$${car.pricePerDay.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color:
                              AppTheme.primaryBlueDark,
                              fontSize: 23,
                              fontWeight:
                              FontWeight.w700,
                              letterSpacing: -1,
                            ),
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'LOADING FLEET...',
            style: TextStyle(
              color: AppTheme.primaryBlueDark,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoadMoreButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.expand_more_rounded,
        ),
        label: const Text(
          'LOAD MORE VEHICLES',
        ),
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