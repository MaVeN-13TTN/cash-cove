import 'package:dio/dio.dart';
import '../../data/providers/api_provider.dart';
import 'dio_client.dart';

class DioApiAdapter extends ApiProvider {
  final DioClient _dioClient;

  DioApiAdapter(this._dioClient) : super(baseUrl: _dioClient.baseUrl);

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'data': []};
      }
      throw _handleError(e);
    }
  }

  @override
  Future<dynamic> post(
    String endpoint,
    dynamic data, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<dynamic> put(
    String endpoint,
    dynamic data, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    dynamic data,
  }) async {
    try {
      final response = await _dioClient.dio.delete(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        queryParameters: queryParameters,
        data: data,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException('Connection timed out. Please try again.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'An error occurred';
        return ApiException(statusCode ?? 500, message);
      default:
        return Exception('An unexpected error occurred');
    }
  }
}
