import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for login and register endpoints
    if (options.path.contains('login') || options.path.contains('register')) {
      return handler.next(options);
    }

    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      // Token expired, try to refresh
      if (!err.requestOptions.path.contains('refresh')) {
        try {
          final refreshToken = await _storage.getRefreshToken();
          if (refreshToken != null) {
            final dio = Dio();
            final response = await dio.post(
              '${err.requestOptions.baseUrl}/auth/token/refresh/',
              data: {'refresh_token': refreshToken},
            );

            if (response.statusCode == 200) {
              final newToken = response.data['access_token'];
              await _storage.setToken(newToken);

              // Retry the original request with new token
              final options = Options(
                method: err.requestOptions.method,
                headers: {
                  ...err.requestOptions.headers,
                  'Authorization': 'Bearer $newToken',
                },
              );

              final retryResponse = await dio.request(
                err.requestOptions.path,
                options: options,
                data: err.requestOptions.data,
                queryParameters: err.requestOptions.queryParameters,
              );

              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          // If refresh fails, clear tokens and let error propagate
          await _storage.clearTokens();
        }
      }
    }
    return handler.next(err);
  }
}