import 'package:dio/dio.dart';

import '../models/pricing_rule.dart';
import 'api_client.dart';

class PricingRuleService {
  Future<List<PricingRule>> getRules() async {
    try {
      final Response<dynamic> response = await ApiClient.dio.get(
        '/api/pricing-rules',
        queryParameters: {'max': 100, 'offset': 0},
      );

      if (response.data is! Map) {
        throw const PricingRuleException(
          'Invalid response from the server.',
        );
      }

      final Map<String, dynamic> body = Map<String, dynamic>.from(
        response.data as Map,
      );

      final List<dynamic> items = body['items'] is List
          ? body['items'] as List<dynamic>
          : <dynamic>[];

      return items
          .whereType<Map>()
          .map((item) => PricingRule.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on PricingRuleException {
      rethrow;
    } on DioException catch (error) {
      throw PricingRuleException(
        _errorMessage(error, 'Failed to load pricing rules.'),
      );
    } catch (_) {
      throw const PricingRuleException(
        'An unexpected error occurred while loading pricing rules.',
      );
    }
  }

  Future<PricingRule> createRule(Map<String, dynamic> data) {
    return _send(
          () => ApiClient.dio.post('/api/pricing-rules', data: data),
      'Failed to create the pricing rule.',
    );
  }

  Future<PricingRule> updateRule(int id, Map<String, dynamic> data) {
    return _send(
          () => ApiClient.dio.put('/api/pricing-rules/$id', data: data),
      'Failed to update the pricing rule.',
    );
  }

  Future<PricingRule> toggleActive(int id) {
    return _send(
          () => ApiClient.dio.post('/api/pricing-rules/$id/toggle-active'),
      'Failed to change the rule state.',
    );
  }

  Future<void> deleteRule(int id) async {
    try {
      await ApiClient.dio.delete('/api/pricing-rules/$id');
    } on DioException catch (error) {
      throw PricingRuleException(
        _errorMessage(error, 'Failed to delete the pricing rule.'),
      );
    }
  }

  Future<PricingRule> _send(
      Future<Response<dynamic>> Function() request,
      String defaultMessage,
      ) async {
    try {
      final Response<dynamic> response = await request();

      if (response.data is! Map) {
        throw const PricingRuleException(
          'Invalid response from the server.',
        );
      }

      return PricingRule.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on PricingRuleException {
      rethrow;
    } on DioException catch (error) {
      throw PricingRuleException(_errorMessage(error, defaultMessage));
    } catch (_) {
      throw PricingRuleException(defaultMessage);
    }
  }

  String _errorMessage(DioException error, String defaultMessage) {
    if (error.type == DioExceptionType.connectionError) {
      return 'Cannot connect to the backend.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'The server took too long to respond.';
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

class PricingRuleException implements Exception {
  final String message;

  const PricingRuleException(this.message);

  @override
  String toString() {
    return message;
  }
}
