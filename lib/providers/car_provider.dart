import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/car.dart';
import '../services/car_service.dart';

class CarsProvider extends ChangeNotifier {
  CarsProvider({
    CarService? carService,
  }) : _carService = carService ?? CarService();

  final CarService _carService;

  final List<Car> _cars = [];

  CarPagination? _pagination;
  String? _errorMessage;

  bool _isLoading = false;
  bool _isLoadingMore = false;

  String _searchQuery = '';
  String? _selectedStatus;

  Timer? _searchDebounce;
  int _requestId = 0;

  List<Car> get cars => List.unmodifiable(_cars);

  String? get errorMessage => _errorMessage;

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  String get searchQuery => _searchQuery;

  String? get selectedStatus => _selectedStatus;

  bool get hasActiveFilters {
    return _searchQuery.isNotEmpty ||
        _selectedStatus != null;
  }

  bool get isEmpty {
    return !_isLoading &&
        _errorMessage == null &&
        _cars.isEmpty;
  }

  bool get hasMore {
    return _pagination?.hasMore ?? false;
  }

  int get totalCars {
    return _pagination?.total ?? _cars.length;
  }

  Future<void> loadCars() async {
    final int currentRequestId = ++_requestId;

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final CarPage page = await _carService.getCars(
        max: 10,
        offset: 0,
        query: _searchQuery,
        status: _selectedStatus,
      );

      if (currentRequestId != _requestId) {
        return;
      }

      _cars
        ..clear()
        ..addAll(page.items);

      _pagination = page.pagination;
    } on CarServiceException catch (error) {
      if (currentRequestId == _requestId) {
        _errorMessage = error.message;
      }
    } catch (_) {
      if (currentRequestId == _requestId) {
        _errorMessage =
        'An unexpected error occurred.';
      }
    } finally {
      if (currentRequestId == _requestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void updateSearchQuery(String value) {
    final String cleanValue = value.trim();

    if (_searchQuery == cleanValue) {
      return;
    }

    _searchQuery = cleanValue;
    _searchDebounce?.cancel();

    notifyListeners();

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      loadCars,
    );
  }

  void updateStatus(String? status) {
    if (_selectedStatus == status) {
      return;
    }

    _selectedStatus = status;
    _searchDebounce?.cancel();

    notifyListeners();
    loadCars();
  }

  Future<void> clearFilters() async {
    _searchDebounce?.cancel();

    _searchQuery = '';
    _selectedStatus = null;

    await loadCars();
  }

  Future<void> loadMoreCars() async {
    if (_isLoading ||
        _isLoadingMore ||
        !hasMore) {
      return;
    }

    final String requestedQuery = _searchQuery;
    final String? requestedStatus =
        _selectedStatus;

    _isLoadingMore = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final int nextOffset =
          _pagination?.nextOffset ?? _cars.length;

      final CarPage page = await _carService.getCars(
        max: 10,
        offset: nextOffset,
        query: requestedQuery,
        status: requestedStatus,
      );

      final bool filtersChanged =
          requestedQuery != _searchQuery ||
              requestedStatus != _selectedStatus;

      if (filtersChanged) {
        return;
      }

      _cars.addAll(page.items);
      _pagination = page.pagination;
    } on CarServiceException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage =
      'Unable to load more cars.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshCars() async {
    _searchDebounce?.cancel();
    await loadCars();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearCars() {
    _requestId++;
    _searchDebounce?.cancel();

    _cars.clear();
    _pagination = null;
    _errorMessage = null;
    _searchQuery = '';
    _selectedStatus = null;
    _isLoading = false;
    _isLoadingMore = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}