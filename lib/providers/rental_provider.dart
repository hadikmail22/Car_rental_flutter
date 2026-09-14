import 'package:flutter/material.dart';

import '../models/create_rental_request.dart';
import '../models/create_rental_response.dart';
import '../models/rental.dart';
import '../services/rental_service.dart';

class RentalsProvider extends ChangeNotifier {
  final RentalService _rentalService = RentalService();

  final List<Rental> _rentals = [];
  final List<Rental> _historyRentals = [];

  final int _pageSize = 10;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isCreating = false;
  bool _isLoadingHistory = false;
  bool _isLoadingMoreHistory = false;

  int? _cancellingRentalId;
  int? _payingDepositRentalId;
  int? _updatingRentalId;

  String? _errorMessage;
  String? _historyErrorMessage;

  CreateRentalResponse? _lastCreatedRental;

  int _offset = 0;
  int _total = 0;
  int _historyOffset = 0;
  int _historyTotal = 0;

  List<Rental> get rentals => List.unmodifiable(_rentals);

  List<Rental> get historyRentals => List.unmodifiable(_historyRentals);

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  bool get isCreating => _isCreating;

  bool get isLoadingHistory => _isLoadingHistory;

  bool get isLoadingMoreHistory => _isLoadingMoreHistory;

  int? get cancellingRentalId => _cancellingRentalId;

  int? get payingDepositRentalId => _payingDepositRentalId;

  int? get updatingRentalId => _updatingRentalId;

  String? get errorMessage => _errorMessage;

  String? get historyErrorMessage => _historyErrorMessage;

  CreateRentalResponse? get lastCreatedRental => _lastCreatedRental;

  bool get hasMore => _rentals.length < _total;

  bool get hasMoreHistory => _historyRentals.length < _historyTotal;

  int get totalRentals => _total;

  int get totalHistoryRentals => _historyTotal;

  bool get isEmpty => _rentals.isEmpty;

  bool get isHistoryEmpty => _historyRentals.isEmpty;

  Future<void> loadRentals() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RentalPage page = await _rentalService.getRentals(
        max: _pageSize,
        offset: 0,
      );

      _rentals
        ..clear()
        ..addAll(page.items);

      _total = page.pagination.total;
      _offset = _rentals.length;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoading || !hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final RentalPage page = await _rentalService.getRentals(
        max: _pageSize,
        offset: _offset,
      );

      _rentals.addAll(page.items);

      _total = page.pagination.total;
      _offset = _rentals.length;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadRentalHistory() async {
    if (_isLoadingHistory) {
      return;
    }

    _isLoadingHistory = true;
    _historyErrorMessage = null;
    notifyListeners();

    try {
      final RentalPage page = await _rentalService.getRentalHistory(
        max: _pageSize,
        offset: 0,
      );

      _historyRentals
        ..clear()
        ..addAll(page.items);

      _historyTotal = page.pagination.total;
      _historyOffset = _historyRentals.length;
    } on RentalServiceException catch (error) {
      _historyErrorMessage = error.message;
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreRentalHistory() async {
    if (_isLoadingMoreHistory || _isLoadingHistory || !hasMoreHistory) {
      return;
    }

    _isLoadingMoreHistory = true;
    _historyErrorMessage = null;
    notifyListeners();

    try {
      final RentalPage page = await _rentalService.getRentalHistory(
        max: _pageSize,
        offset: _historyOffset,
      );

      _historyRentals.addAll(page.items);

      _historyTotal = page.pagination.total;
      _historyOffset = _historyRentals.length;
    } on RentalServiceException catch (error) {
      _historyErrorMessage = error.message;
    } finally {
      _isLoadingMoreHistory = false;
      notifyListeners();
    }
  }

  Future<CreateRentalResponse?> createRental(
    CreateRentalRequest request,
  ) async {
    if (_isCreating) {
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    _lastCreatedRental = null;
    notifyListeners();

    try {
      _lastCreatedRental = await _rentalService.createRental(request);

      await loadRentals();

      return _lastCreatedRental;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
      return null;
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  Future<Rental?> payDeposit(int rentalId) async {
    if (_payingDepositRentalId != null) {
      return null;
    }

    _payingDepositRentalId = rentalId;
    _errorMessage = null;
    notifyListeners();

    try {
      final Rental rental = await _rentalService.payDeposit(rentalId);

      _replaceActive(rental);

      return rental;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
      return null;
    } finally {
      _payingDepositRentalId = null;
      notifyListeners();
    }
  }

  Future<bool> cancelRental(int rentalId) async {
    if (_cancellingRentalId != null) {
      return false;
    }

    _cancellingRentalId = rentalId;
    _errorMessage = null;
    notifyListeners();

    try {
      final Rental rental = await _rentalService.cancelRental(rentalId);

      _rentals.removeWhere((item) => item.id == rentalId);

      if (_total > 0) {
        _total--;
      }

      _offset = _rentals.length;

      _historyRentals.removeWhere((item) => item.id == rentalId);

      _historyRentals.insert(0, rental);
      _historyTotal++;
      _historyOffset = _historyRentals.length;

      return true;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _cancellingRentalId = null;
      notifyListeners();
    }
  }

  Future<bool> pickupRental(int rentalId) {
    return _adminUpdate(rentalId, () => _rentalService.pickupRental(rentalId));
  }

  Future<bool> completeRental(int rentalId, {double damageCost = 0}) {
    return _adminUpdate(
      rentalId,
      () => _rentalService.completeRental(rentalId, damageCost: damageCost),
    );
  }

  Future<bool> _adminUpdate(
    int rentalId,
    Future<Rental> Function() request,
  ) async {
    if (_updatingRentalId != null) {
      return false;
    }

    _updatingRentalId = rentalId;
    _errorMessage = null;
    notifyListeners();

    try {
      final Rental rental = await request();

      _replaceActive(rental);

      return true;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
      return false;
    } finally {
      _updatingRentalId = null;
      notifyListeners();
    }
  }

  void _replaceActive(Rental rental) {
    final int index = _rentals.indexWhere((item) => item.id == rental.id);

    if (index != -1) {
      _rentals[index] = rental;
    }
  }

  Future<void> refreshRentals() {
    return loadRentals();
  }

  Future<void> refreshRentalHistory() {
    return loadRentalHistory();
  }

  Future<void> loadMoreRentals() {
    return loadMore();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearFeedback() {
    clearError();
  }

  void clearHistoryError() {
    _historyErrorMessage = null;
    notifyListeners();
  }

  void clearRentals() {
    _rentals.clear();
    _historyRentals.clear();

    _offset = 0;
    _total = 0;
    _historyOffset = 0;
    _historyTotal = 0;

    _errorMessage = null;
    _historyErrorMessage = null;
    _lastCreatedRental = null;

    notifyListeners();
  }
}
