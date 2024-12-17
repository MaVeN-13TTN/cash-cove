import 'package:dio/dio.dart';
import '../../data/providers/api_provider.dart';
import '../services/storage/secure_storage.dart';
import '../utils/logger_utils.dart';
import 'dio_client.dart';

class DioApiAdapter extends ApiProvider {
  final DioClient _dioClient;
  late final SecureStorage _secureStorage;

  DioApiAdapter(this._dioClient, SecureStorage secureStorage)
      : _secureStorage = secureStorage,
        super(
          dio: _dioClient.dio,
          storage: secureStorage,
        );

  static Future<DioApiAdapter> initialize(DioClient dioClient) async {
    final storage = await SecureStorage.initialize();
    return DioApiAdapter(dioClient, storage);
  }

  @override
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    try {
      LoggerUtils.info('GET request to: $endpoint');
      final response = await _dioClient.dio.get(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        queryParameters: queryParameters,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'data': []};
      }
      throw _handleError(e);
    } catch (e) {
      LoggerUtils.error('Unexpected error during GET request', e);
      rethrow;
    }
  }

  @override
  Future<dynamic> post(String endpoint, dynamic data, {Map<String, dynamic>? queryParameters}) async {
    try {
      LoggerUtils.info('POST request to: $endpoint');
      final response = await _dioClient.dio.post(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      LoggerUtils.error('Unexpected error during POST request', e);
      rethrow;
    }
  }

  @override
  Future<dynamic> put(String endpoint, dynamic data, {Map<String, dynamic>? queryParameters}) async {
    try {
      LoggerUtils.info('PUT request to: $endpoint');
      final response = await _dioClient.dio.put(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        data: data,
        queryParameters: queryParameters,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      LoggerUtils.error('Unexpected error during PUT request', e);
      rethrow;
    }
  }

  @override
  Future<dynamic> delete(String endpoint, {Map<String, dynamic>? queryParameters, dynamic data}) async {
    try {
      LoggerUtils.info('DELETE request to: $endpoint');
      final response = await _dioClient.dio.delete(
        endpoint.endsWith('/') ? endpoint : '$endpoint/',
        queryParameters: queryParameters,
        data: data,
        options: Options(
          headers: await _getAuthHeaders(),
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    } catch (e) {
      LoggerUtils.error('Unexpected error during DELETE request', e);
      rethrow;
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  ApiException _handleError(DioException e) {
    LoggerUtils.error('DioError: ${e.message}', e, e.stackTrace);
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Connection timed out. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null) {
          final data = response.data;
          final message = data is Map ? data['message'] ?? data['detail'] ?? e.message : e.message;
          return ApiException(
            message.toString(),
            statusCode: response.statusCode,
            error: data,
          );
        }
        return ApiException(
          e.message ?? 'Bad response from server',
          statusCode: 500,
        );
      default:
        return ApiException(
          e.message ?? 'An unexpected error occurred',
          error: e,
        );
    }
  }
}
