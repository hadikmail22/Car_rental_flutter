import 'package:dio/dio.dart';

import '../models/car.dart';
import '../models/car_catalog.dart';
import 'api_client.dart';

class CarService {
  Future<CarPage> getCars({
    int max = 10,
    int offset = 0,
    String? query,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {
        'max': max,
        'offset': offset,
      };

      final String cleanQuery = query?.trim() ?? '';

      if (cleanQuery.isNotEmpty) {
        queryParameters['q'] = cleanQuery;
      }

      if (status != null && status.isNotEmpty) {
        queryParameters['status'] = status;
      }

      final Response<dynamic> response =
      await ApiClient.dio.get(
        '/api/cars',
        queryParameters: queryParameters,
      );

      if (response.data is! Map) {
        throw const CarServiceException(
          'Invalid cars response from the server.',
        );
      }

      final Map<String, dynamic> responseJson =
      Map<String, dynamic>.from(
        response.data as Map,
      );

      return CarPage.fromJson(responseJson);
    } on CarServiceException {
      rethrow;
    } on DioException catch (error) {
      if (error.type ==
          DioExceptionType.connectionTimeout ||
          error.type ==
              DioExceptionType.receiveTimeout ||
          error.type ==
              DioExceptionType.sendTimeout) {
        throw const CarServiceException(
          'Cars request timed out.',
        );
      }

      if (error.type ==
          DioExceptionType.connectionError) {
        throw const CarServiceException(
          'Cannot connect to the backend.',
        );
      }

      final int? statusCode =
          error.response?.statusCode;

      if (statusCode == 401 ||
          statusCode == 403) {
        throw const CarServiceException(
          'Your session has expired. Please login again.',
        );
      }

      throw CarServiceException(
        'Failed to load cars. Server error: '
            '${statusCode ?? 'unknown'}',
      );
    } catch (_) {
      throw const CarServiceException(
        'An unexpected error occurred while loading cars.',
      );
    }
  }

  Future<CarCatalog> getCatalog() async {
    try {
      final Response<dynamic> response = await ApiClient.dio.get(
        '/api/catalog',
      );

      if (response.data is! Map) {
        throw const CarServiceException(
          'Invalid catalogue response from the server.',
        );
      }

      return CarCatalog.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on CarServiceException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionError) {
        throw const CarServiceException('Cannot connect to the backend.');
      }

      final int? statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        throw const CarServiceException(
          'Your session has expired. Please login again.',
        );
      }

      throw CarServiceException(
        'Failed to load the catalogue. Server error: '
            '${statusCode ?? 'unknown'}',
      );
    } catch (_) {
      throw const CarServiceException(
        'An unexpected error occurred while loading the catalogue.',
      );
    }
  }

  Future<int> createCar({
    required int brandId,
    required int modelId,
    required int year,
    required String plateNumber,
    required double pricePerDay,
    required String status,
    int? categoryId,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'brandId': brandId,
        'modelId': modelId,
        'year': year,
        'plateNumber': plateNumber.trim().toUpperCase(),
        'pricePerDay': pricePerDay,
        'status': status,
      };

      if (categoryId != null) {
        body['categoryId'] = categoryId;
      }

      final Response<dynamic> response = await ApiClient.dio.post(
        '/api/cars',
        data: body,
      );

      if (response.data is! Map) {
        throw const CarServiceException(
          'Invalid response from the server.',
        );
      }

      final Map<String, dynamic> responseJson = Map<String, dynamic>.from(
        response.data as Map,
      );

      return (responseJson['id'] as num).toInt();
    } on CarServiceException {
      rethrow;
    } on DioException catch (error) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw const CarServiceException('Request timed out.');
      }

      if (error.type == DioExceptionType.connectionError) {
        throw const CarServiceException('Cannot connect to the backend.');
      }

      final int? statusCode = error.response?.statusCode;

      if (statusCode == 401 || statusCode == 403) {
        throw const CarServiceException(
          'Your session has expired. Please login again.',
        );
      }

      final dynamic data = error.response?.data;

      if (data is Map) {
        final dynamic errors = data['errors'];

        if (errors is List && errors.isNotEmpty) {
          throw CarServiceException(errors.join('\n'));
        }

        if (data['error'] != null) {
          throw CarServiceException(data['error'].toString());
        }
      }

      throw CarServiceException(
        'Failed to add car. Server error: ${statusCode ?? 'unknown'}',
      );
    } catch (_) {
      throw const CarServiceException(
        'An unexpected error occurred while adding the car.',
      );
    }
  }

  Future<void> updateCar({
    required int id,
    required int brandId,
    required int modelId,
    required int year,
    required String plateNumber,
    required double pricePerDay,
    required String status,
    int? categoryId,
  }) async {
    final Map<String, dynamic> body = {
      'brandId': brandId,
      'modelId': modelId,
      'year': year,
      'plateNumber': plateNumber.trim().toUpperCase(),
      'pricePerDay': pricePerDay,
      'status': status,
    };

    // The server rejects an empty categoryId,
    // so it is only sent when a category is chosen.
    if (categoryId != null) {
      body['categoryId'] = categoryId;
    }

    try {
      await ApiClient.dio.put('/api/cars/$id', data: body);
    } on DioException catch (error) {
      throw CarServiceException(
        _writeErrorMessage(error, 'Failed to update the car.'),
      );
    }
  }

  Future<void> deleteCar(int id) async {
    try {
      await ApiClient.dio.delete('/api/cars/$id');
    } on DioException catch (error) {
      throw CarServiceException(
        _writeErrorMessage(error, 'Failed to delete the car.'),
      );
    }
  }

  String _writeErrorMessage(DioException error, String defaultMessage) {
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to the backend.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Request timed out.';
    }

    final int? statusCode = error.response?.statusCode;

    if (statusCode == 401 || statusCode == 403) {
      return 'Your session has expired. Please login again.';
    }

    final dynamic data = error.response?.data;

    if (data is Map) {
      final dynamic errors = data['errors'];

      if (errors is List && errors.isNotEmpty) {
        return errors.join('\n');
      }

      if (data['error'] != null) {
        return data['error'].toString();
      }
    }

    return '$defaultMessage Server error: ${statusCode ?? 'unknown'}';
  }
}

class CarServiceException implements Exception {
  final String message;

  const CarServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}