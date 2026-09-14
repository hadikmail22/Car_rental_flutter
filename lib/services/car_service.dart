import 'package:dio/dio.dart';

import '../models/car.dart';
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
}

class CarServiceException implements Exception {
  final String message;

  const CarServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}