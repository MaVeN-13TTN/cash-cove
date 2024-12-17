import 'package:dio/dio.dart';
import '../../../core/services/storage/secure_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic error;

  ApiException(this.message, {this.statusCode, this.error});

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' ($statusCode)' : ''}${error != null ? '\nError: $error' : ''}';
}

class ApiProvider {
  final Dio _dio;
  final SecureStorage _storage;

  ApiProvider({
    required Dio dio,
    required SecureStorage storage,
  })  : _dio = dio,
        _storage = storage;

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _storage.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> setAuthToken(String token) async {
    await _storage.setToken(token);
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _dio.get(
        endpoint,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to perform GET request', error: e);
    }
  }

  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: data,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to perform POST request', error: e);
    }
  }

  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final response = await _dio.put(
        endpoint,
        data: data,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to perform PUT request', error: e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _dio.delete(
        endpoint,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
    } catch (e) {
      throw ApiException('Failed to perform DELETE request', error: e);
    }
  }

  Never _handleDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      final message = data is Map ? data['message'] ?? data['detail'] ?? e.message : e.message;
      throw ApiException(
        message.toString(),
        statusCode: response.statusCode,
        error: data,
      );
    }

    throw ApiException(
      e.message ?? 'Network error occurred',
      error: e,
    );
  }
}
