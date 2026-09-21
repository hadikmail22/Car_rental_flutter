import 'package:dio/dio.dart';

import '../models/create_rental_request.dart';
import '../models/create_rental_response.dart';
import '../models/rental.dart';
import 'api_client.dart';

class RentalService {
  Future<RentalPage> getRentals({int max = 10, int offset = 0}) {
    return _getRentalPage('/api/rentals', max: max, offset: offset);
  }

  Future<RentalPage> getRentalHistory({int max = 10, int offset = 0}) {
    return _getRentalPage('/api/rentals/history', max: max, offset: offset);
  }

  Future<RentalPage> _getRentalPage(
      String path, {
        required int max,
        required int offset,
      }) async {
    try {
      final Response<dynamic> response = await ApiClient.dio.get(
        path,
        queryParameters: {'max': max, 'offset': offset},
      );

      return RentalPage.fromJson(_requireJsonMap(response.data));
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(error, defaultMessage: 'Failed to load rentals.'),
      );
    } catch (_) {
      throw const RentalServiceException(
        'Invalid rentals response from the server.',
      );
    }
  }

  Future<Rental> getRentalById(int rentalId) async {
    try {
      final Response<dynamic> response = await ApiClient.dio.get(
        '/api/rentals/$rentalId',
      );

      return Rental.fromJson(_requireJsonMap(response.data));
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(error, defaultMessage: 'Failed to load rental.'),
      );
    } catch (_) {
      throw const RentalServiceException(
        'Invalid rental response from the server.',
      );
    }
  }

  Future<CreateRentalResponse> createRental(CreateRentalRequest request) async {
    try {
      final Response<dynamic> response = await ApiClient.dio.post(
        '/api/rentals',
        data: request.toJson(),
      );

      return CreateRentalResponse.fromJson(_requireJsonMap(response.data));
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(error, defaultMessage: 'Failed to create rental.'),
      );
    } catch (_) {
      throw const RentalServiceException(
        'Invalid create rental response from the server.',
      );
    }
  }

  Future<Rental> payDeposit(int rentalId) {
    return _postAndRead('/api/rentals/$rentalId/pay-deposit', rentalId);
  }

  Future<Rental> cancelRental(int rentalId) {
    return _postAndRead('/api/rentals/$rentalId/cancel', rentalId);
  }

  Future<Rental> pickupRental(int rentalId) {
    return _postAndRead('/api/rentals/$rentalId/pickup', rentalId);
  }

  Future<Rental> completeRental(int rentalId, {double damageCost = 0}) {
    return _postAndRead(
      '/api/rentals/$rentalId/complete',
      rentalId,
      data: {'damageCost': damageCost},
    );
  }

  Future<Rental> _postAndRead(
      String path,
      int rentalId, {
        Map<String, dynamic>? data,
      }) async {
    try {
      final Response<dynamic> response = await ApiClient.dio.post(
        path,
        data: data,
      );

      if (response.data is Map) {
        return Rental.fromJson(_requireJsonMap(response.data));
      }

      return getRentalById(rentalId);
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(error, defaultMessage: 'Failed to update rental.'),
      );
    } catch (_) {
      throw const RentalServiceException(
        'Invalid rental response from the server.',
      );
    }
  }

  Future<void> deleteRental(int rentalId) async {
    try {
      await ApiClient.dio.delete('/api/rentals/$rentalId');
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(error, defaultMessage: 'Failed to delete rental.'),
      );
    } catch (_) {
      throw const RentalServiceException('Unable to delete rental.');
    }
  }

  Map<String, dynamic> _requireJsonMap(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const RentalServiceException('Server response is not a JSON object.');
  }

  String _getDioErrorMessage(
      DioException error, {
        required String defaultMessage,
      }) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The backend request timed out.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to the backend. Make sure Grails is running.';
    }

    final int? statusCode = error.response?.statusCode;
    final dynamic data = error.response?.data;

    if (data is Map && data['error'] != null) {
      return data['error'].toString();
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Your session has expired. Please login again.';
    }

    return '$defaultMessage Server error: ${statusCode ?? 'unknown'}';
  }

  /// Asks the server for the real price before the rental is created.
  /// Uses the same quote endpoint the web application uses.
  Future<RentalQuote> getQuote({
    required int carId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final Response<dynamic> response = await ApiClient.dio.get(
        '/rental/quote',
        queryParameters: {
          'carId': carId,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );

      if (response.data is! Map) {
        throw const RentalServiceException(
          'Invalid quote response from the server.',
        );
      }

      return RentalQuote.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage: 'Failed to calculate the price.',
        ),
      );
    } catch (_) {
      throw const RentalServiceException(
        'An unexpected error occurred while calculating the price.',
      );
    }
  }

  String _formatDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}

class RentalQuote {
  final int rentalDays;
  final double baseTotal;
  final double totalPrice;
  final double adjustmentAmount;
  final bool hasDynamicPricing;

  const RentalQuote({
    required this.rentalDays,
    required this.baseTotal,
    required this.totalPrice,
    required this.adjustmentAmount,
    required this.hasDynamicPricing,
  });

  factory RentalQuote.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return RentalQuote(
      rentalDays: (json['rentalDays'] as num?)?.toInt() ?? 0,
      baseTotal: toDouble(json['baseTotal']),
      totalPrice: toDouble(json['totalPrice']),
      adjustmentAmount: toDouble(json['adjustmentAmount']),
      hasDynamicPricing: json['hasDynamicPricing'] == true,
    );
  }

  bool get hasDiscount => adjustmentAmount < 0;

  bool get hasSurcharge => adjustmentAmount > 0;
}

class RentalServiceException implements Exception {
  final String message;

  const RentalServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
