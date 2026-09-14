import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/car.dart';
import '../providers/car_provider.dart';
import '../theme/app_theme.dart';
import '../screens/car_details_screen.dart';

class CarsCatalog extends StatefulWidget {
  const CarsCatalog({super.key});

  @override
  State<CarsCatalog> createState() =>
      _CarsCatalogState();
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
          const LinearProgressIndicator(),

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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
      onRefresh: provider.refreshCars,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          24,
        ),
        itemCount: provider.cars.length +
            (provider.hasMore ||
                provider.isLoadingMore
                ? 1
                : 0),
        separatorBuilder: (context, index) {
          return const SizedBox(height: 12);
        },
        itemBuilder: (context, index) {
          if (index == provider.cars.length) {
            return _LoadMoreButton(
              isLoading: provider.isLoadingMore,
              onPressed: provider.loadMoreCars,
            );
          }

          final Car car = provider.cars[index];

          return _CarCard(car: car);
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

  @override
  Widget build(BuildContext context) {
    const List<String> statuses = [
      'AVAILABLE',
      'RENTED',
      'MAINTENANCE',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: provider.updateSearchQuery,
            decoration: InputDecoration(
              hintText:
              'Search brand, model or plate...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: provider.searchQuery.isEmpty
                  ? null
                  : IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  provider.updateSearchQuery('');
                },
                icon: const Icon(Icons.close),
              ),
              border: const OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected:
                  provider.selectedStatus == null,
                  onSelected: (_) {
                    provider.updateStatus(null);
                  },
                ),

                const SizedBox(width: 8),

                ...statuses.map((status) {
                  return Padding(
                    padding:
                    const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        _formatStatus(status),
                      ),
                      selected:
                      provider.selectedStatus ==
                          status,
                      onSelected: (_) {
                        provider.updateStatus(status);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                '${provider.totalCars} cars found',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              if (provider.hasActiveFilters)
                TextButton.icon(
                  onPressed: onClearAll,
                  icon: const Icon(
                    Icons.filter_alt_off,
                    size: 18,
                  ),
                  label: const Text('Clear filters'),
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

class _CarCard extends StatelessWidget {
  final Car car;

  const _CarCard({
    required this.car,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = car.isAvailable
        ? Colors.green
        : car.status == 'MAINTENANCE'
        ? Colors.red
        : Colors.orange.shade700;

    return Card(
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CarDetailsScreen(car: car),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              _CarImage(imageUrl: car.imageUrl),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      '${car.year} • '
                          '${car.category ?? 'Uncategorized'}',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '\$${car.pricePerDay.toStringAsFixed(2)} / day',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      child: Text(
                        car.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
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
      width: 92,
      height: 92,
      color: AppTheme.primaryYellow,
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled,
        size: 46,
        color: AppTheme.darkColor,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: imageUrl == null || imageUrl!.isEmpty
          ? fallback
          : Image.network(
        imageUrl!,
        width: 92,
        height: 92,
        fit: BoxFit.cover,
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

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.expand_more),
      label: const Text('Load more cars'),
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
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load cars',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'No matching cars'
                  : 'No cars available',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Try changing your search or filters.'
                  : 'There are no cars to display right now.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            if (hasFilters)
              OutlinedButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(
                  Icons.filter_alt_off,
                ),
                label: const Text('Clear filters'),
              )
            else
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
          ],
        ),
      ),
    );
  }
}
