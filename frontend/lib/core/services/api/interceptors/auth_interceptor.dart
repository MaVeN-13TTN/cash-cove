import 'package:dio/dio.dart';
import '../../auth/token_manager.dart';
import '../../../utils/logger_utils.dart';

class AuthInterceptor extends Interceptor {
  final TokenManager _tokenManager;
  final List<String> _publicEndpoints = [
    'token',
    'register',
    'check-email',
    'forgot-password',
    'reset-password',
  ];

  AuthInterceptor(this._tokenManager);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth header for public endpoints
    if (_publicEndpoints.any((endpoint) => options.path.contains(endpoint))) {
      return handler.next(options);
    }

    final token = await _tokenManager.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    } else {
      // If no token is available, try to refresh
      try {
        final refreshToken = await _tokenManager.getRefreshToken();
        if (refreshToken != null) {
          final dio = Dio();
          final response = await dio.post(
            '${options.baseUrl}/auth/token/refresh/',
            data: {'refresh': refreshToken},
          );

          if (response.statusCode == 200) {
            final newToken = response.data['access'];
            final newRefreshToken = response.data['refresh'];
            await _tokenManager.setTokens(
              accessToken: newToken,
              refreshToken: newRefreshToken,
            );
            options.headers['Authorization'] = 'Bearer $newToken';
          }
        }
      } catch (e) {
        LoggerUtils.error('Failed to refresh token', e);
      }
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
          final refreshToken = await _tokenManager.getRefreshToken();
          if (refreshToken != null) {
            final dio = Dio();
            final response = await dio.post(
              '${err.requestOptions.baseUrl}/auth/token/refresh/',
              data: {'refresh': refreshToken},
            );

            if (response.statusCode == 200) {
              final newToken = response.data['access'];
              final newRefreshToken = response.data['refresh'];
              await _tokenManager.setTokens(
                accessToken: newToken,
                refreshToken: newRefreshToken,
              );

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
                data: err.requestOptions.data,
                queryParameters: err.requestOptions.queryParameters,
                options: options,
              );

              return handler.resolve(retryResponse);
            }
          }
        } catch (e) {
          // If refresh fails, clear tokens and let error propagate
          await _tokenManager.clearTokens();
          LoggerUtils.error('Token refresh failed', e);
        }
      }
    }

    return handler.next(err);
  }
}