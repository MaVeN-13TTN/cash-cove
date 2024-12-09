import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import '../../utils/storage_utils.dart';
import '../../../modules/auth/controllers/auth_controller.dart';
import '../../services/error/error_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final ErrorService _errorService;
  bool _isRefreshing = false;
  
  AuthInterceptor({
    required Dio dio,
    required ErrorService errorService,
  })  : _dio = dio,
        _errorService = errorService;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await StorageUtils.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        // If already refreshing, queue the request
        final retryResponse = await _retryRequest(err.requestOptions);
        handler.resolve(retryResponse);
        return;
      }

      try {
        _isRefreshing = true;
        final newToken = await _refreshToken();
        
        if (newToken != null) {
          // Retry the failed request with new token
          final retryResponse = await _retryRequest(err.requestOptions, newToken);
          handler.resolve(retryResponse);
          return;
        }
      } catch (refreshError) {
        _errorService.handleError(refreshError);
        // Force logout on refresh token failure
        Get.find<AuthController>().logout();
      } finally {
        _isRefreshing = false;
      }
    }
    
    // Handle other errors
    _errorService.handleError(err);
    handler.next(err);
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshToken = await StorageUtils.getRefreshToken();
      if (refreshToken == null) {
        throw DioException(
          requestOptions: RequestOptions(path: ''),
          error: 'No refresh token available',
        );
      }

      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newToken = response.data['access'];
        await StorageUtils.setAccessToken(newToken);
        return newToken;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions, [
    String? newToken,
  ]) async {
    final options = Options(
      method: requestOptions.method,
      headers: requestOptions.headers,
    );

    if (newToken != null) {
      options.headers?['Authorization'] = 'Bearer $newToken';
    }

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}
