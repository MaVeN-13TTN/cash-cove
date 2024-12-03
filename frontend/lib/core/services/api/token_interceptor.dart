import 'package:dio/dio.dart' as dio_client;
import 'package:get/get.dart';
import '../../utils/storage_utils.dart';

class TokenInterceptor extends dio_client.Interceptor {
  final dio_client.Dio dio;
  bool _isRefreshing = false;
  final List<dio_client.RequestOptions> _pendingRequests = [];

  TokenInterceptor(this.dio);

  @override
  void onRequest(dio_client.RequestOptions options, dio_client.RequestInterceptorHandler handler) async {
    // Set content type for all requests
    options.headers['Content-Type'] = 'application/json';
    
    final accessToken = await StorageUtils.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    return handler.next(options);
  }

  @override
  void onError(dio_client.DioException err, dio_client.ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        // Queue the request if we're already refreshing
        _pendingRequests.add(err.requestOptions);
        return;
      }

      try {
        _isRefreshing = true;
        final newTokens = await _refreshToken();
        if (newTokens != null) {
          // Retry the failed request
          final response = await _retryRequest(err.requestOptions);
          // Process queued requests
          await _processPendingRequests();
          return handler.resolve(response);
        }
      } catch (e) {
        // Handle refresh token failure
        await StorageUtils.clearTokens();
        // Redirect to login
        Get.offAllNamed('/login');
      } finally {
        _isRefreshing = false;
        _pendingRequests.clear();
      }
    }
    return handler.next(err);
  }

  Future<Map<String, dynamic>?> _refreshToken() async {
    final refreshToken = await StorageUtils.getRefreshToken();
    if (refreshToken == null) return null;

    try {
      final response = await dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final tokens = response.data;
        await StorageUtils.saveToken('access_token', tokens['access']);
        await StorageUtils.saveToken('refresh_token', tokens['refresh']);
        return tokens;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<dio_client.Response<dynamic>> _retryRequest(dio_client.RequestOptions requestOptions) async {
    final accessToken = await StorageUtils.getAccessToken();
    final options = dio_client.Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $accessToken',
      },
    );

    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }

  Future<void> _processPendingRequests() async {
    final requests = List<dio_client.RequestOptions>.from(_pendingRequests);
    _pendingRequests.clear();

    for (var request in requests) {
      await _retryRequest(request);
    }
  }
}
