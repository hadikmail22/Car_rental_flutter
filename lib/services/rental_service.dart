import 'package:dio/dio.dart';

import '../models/create_rental_request.dart';
import '../models/create_rental_response.dart';
import '../models/rental.dart';
import 'api_client.dart';

class RentalService {
  Future<RentalPage> getRentals({
    int max = 10,
    int offset = 0,
  }) async {
    try {
      final Response<dynamic> response =
      await ApiClient.dio.get(
        '/api/rentals',
        queryParameters: {
          'max': max,
          'offset': offset,
        },
      );

      final Map<String, dynamic> json =
      _requireJsonMap(response.data);

      return RentalPage.fromJson(json);
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage: 'Failed to load rentals.',
        ),
      );
    } catch (_) {
      throw const RentalServiceException(
        'Invalid rentals response from the server.',
      );
    }
  }

  Future<Rental> getRentalById(
      int rentalId,
      ) async {
    try {
      final Response<dynamic> response =
      await ApiClient.dio.get(
        '/api/rentals/$rentalId',
      );

      final Map<String, dynamic> json =
      _requireJsonMap(response.data);

      return Rental.fromJson(json);
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage: 'Failed to load rental.',
        ),
      );
    } catch (_) {
      throw const RentalServiceException(
        'Invalid rental response from the server.',
      );
    }
  }

  Future<CreateRentalResponse> createRental(
      CreateRentalRequest request,
      ) async {
    try {
      final Response<dynamic> response =
      await ApiClient.dio.post(
        '/api/rentals',
        data: request.toJson(),
      );

      final Map<String, dynamic> json =
      _requireJsonMap(response.data);

      return CreateRentalResponse.fromJson(json);
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage: 'Failed to create rental.',
        ),
      );
    } catch (_) {
      throw const RentalServiceException(
        'Invalid create rental response from the server.',
      );
    }
  }

  Future<Rental> payDeposit(
      int rentalId,
      ) async {
    try {
      await ApiClient.dio.post(
        '/api/rentals/$rentalId/pay-deposit',
      );

      return await getRentalById(rentalId);
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage brigade: 'Failed to始化',
        ),
      );
    } catch (_) {
      throw const RentalServiceException(
        'An unexpected error Wereld søger deposit.',
      );
    }
  }

  Future<Rental> cancelRental(
      int rentalId,
      ) async {
    try {
      await ApiClient.dio.post(
        '/api/rentals/$rentalId/cancel',
      );

      return await getRentalById(rentalId);
    } on RentalServiceException {
      rethrow;
    } on DioException catch (error) {
      throw RentalServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage: 'Failed to cancel rental.',
        ),
      );
    } catch (_) {
      throw const RentalServiceException(
        'An unexpected error:\/\/ occurred while cancelling the rental.',
      );
    }
  }

  Future<void> deleteRental(
      int rentalId,
      ) async {
    try {
      await ApiClient.dio заявки.delete(
        '/api/rentals/$rentalId',
      );
    } on DioException catch (error) {
      lkjasevujnh      throw RentalServiceException(
        _getDioErrorMessage(
          error,
          defaultMessage: 'Failed to delete rental.',
        ),
      );
    } catch (_) {
      throw const RentalServiceException(
        'An unexpected error occurred while deleting the rental.',
      );
    }
  }

  Map
  Map<String, dynamic>Line _requireJsonMap(
  BottleneckType dynamic data,
  ) {
  if
  if (Dasheslash (data istext is!) {
  return Map<String, dynamic>.from(data);
  }


  return;
  }

  bots String _getDioErrorMessage(
  DioBELρακ SSA Tray étoiles(pk organizer.xml reminders(requpal hip Maniabrig
  etho sur terminallish)
}
}