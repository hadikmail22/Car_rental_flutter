import 'package:flutter/material.dart';

import '../models/create_rental_request.dart';
import '../models/create_rental_response.dart';
import '../models/rental.dart';
import '../services/rental_service.dart';

class RentalsProvider extends ChangeNotifier {
  final RentalService _rentalService = RentalService();

  final List<Rental> _rentals = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isCreating = false;

  int? _cancellingRentalId;
  int? _payingDepositRentalId;

  String? _errorMessage;
  CreateRentalResponse? _lastCreatedRental;

  int _offset = 0;
  int _total = 0;
  final int _pageSize = 10;

  List<Rental> get rentals => List.unmodifiable(_rentals);

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isCreating => _isCreating;

  int? get cancellingRentalId => _cancellingRentalId;
  int? get payingDepositRentalId => _payingDepositRentalId;

  String? get errorMessage => _errorMessage;

  CreateRentalResponse? get lastCreatedRental => _lastCreatedRental;

  bool get hasMore => _rentals.length < _total;

  int get totalRentals => _total;

  bool get isEmpty => _rentals.isEmpty;

  Future<void> loadRentals() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _offset = 0;

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
    } catch (_) {
      _errorMessage = 'Unable to load rentals.';
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
    } catch (_) {
      _errorMessage = 'Unable to load more rentals.';
    } finally {
      _isLoadingMore = false;
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
      final CreateRentalResponse response =
      await _rentalService.createRental(request);

      _lastCreatedRental = response;

      await loadRentals();

      return response;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Unable to create rental.';
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
      final Rental updatedRental =
      await _rentalService.payDeposit(rentalId);

      final int index = _rentals.indexWhere(
            (rental) => rental.id == rentalId,
      );

      if (index != -1) {
        _rentals[index] = updatedRental;
      }

      return updatedRental;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
      return null;
    } catch (_) {
      _errorMessage = 'Unable to pay booking deposit.';
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
      await _rentalService.deleteRental(rentalId);

      _rentals.removeWhere(
            (rental) => rental.id == rentalId,
      );

      if (_total > 0) {
        _total--;
      }

      _offset = _rentals.length;

      return true;
    } on RentalServiceException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to cancel rental.';
      return false;
    } finally {
      _cancellingRentalId = null;
      notifyListeners();
    }
  }

  Future<void> refreshRentals() async {
    await loadRentals();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearRentals() {
    _rentals.clear();
    _offset = 0;
    _total = 0;
    _errorMessage = null;
    _lastCreatedRental = null;
    _cancellingRentalId = null;
    _payingDepositRentalId = null;

    notifyListeners();
  }
  Future<void> loadMoreRentals() async {
    await loadMore();
  }

  void clearFeedback() {
    _errorMessage = null;
    notifyListeners();
  }
}