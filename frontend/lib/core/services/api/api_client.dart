import 'package:dio/dio.dart' as dio_client;
import 'package:get/get.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:hive/hive.dart';
import '../../utils/logger_utils.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import 'interceptors/rate_limit_interceptor.dart';
import 'request_manager.dart';
import '../auth/token_manager.dart';
import '../auth/auth_service.dart';
import '../../services/dialog/dialog_service.dart';
import 'offline_queue_service.dart';
import 'token_interceptor.dart';
import '../hive_service.dart';

class ApiClient extends GetxService {
  late dio_client.Dio _dio;
  // Public getter for Dio instance
  dio_client.Dio get dio => _dio;

  late final OfflineQueueService _offlineQueue;
  late RequestManager _requestManager;
  final DefaultCacheManager _cacheManager;
  final _metrics = <String, List<int>>{};
  static ApiClient? _instance;

  ApiClient._({
    required TokenManager tokenManager, 
    required DefaultCacheManager cacheManager,
    required Box<String> offlineRequestBox,
  }) : 
    _cacheManager = cacheManager {
    _dio = dio_client.Dio(
      dio_client.BaseOptions(
        baseUrl: 'http://127.0.0.1:8000/api/v1',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
        },
        validateStatus: (status) {
          return status! < 500;
        },
        receiveDataWhenStatusError: true,
        extra: {
          'withCredentials': true,
        },
      ),
    );

    // Initialize request manager
    _requestManager = RequestManager(dio: _dio);
    
    // Initialize offline queue
    _offlineQueue = OfflineQueueService(
      dio: _dio,
      box: offlineRequestBox,
    );
  }

  static Future<ApiClient> initialize({
    required String baseUrl,
    required TokenManager tokenManager,
    dio_client.Dio? testDio,
  }) async {
    if (_instance == null) {
      final cacheManager = DefaultCacheManager();
      final authService = Get.find<AuthService>();
      final dialogService = Get.find<DialogService>();
      
      // Get the offline requests box through HiveService
      final hiveService = HiveService();
      final offlineRequestBox = await hiveService.getOfflineRequestsBox();

      _instance = ApiClient._(
        tokenManager: tokenManager, 
        cacheManager: cacheManager,
        offlineRequestBox: offlineRequestBox,
      );

      // Configure base URL and timeout
      _instance!._dio.options.baseUrl = baseUrl;
      _instance!._dio.options.connectTimeout = const Duration(seconds: 30);
      _instance!._dio.options.receiveTimeout = const Duration(seconds: 30);
      _instance!._dio.options.sendTimeout = const Duration(seconds: 30);

      // Update CORS headers
      _instance!._dio.options.headers.addAll({
        'Access-Control-Allow-Origin': 'http://127.0.0.1:8000',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization, X-Request-With',
        'Access-Control-Allow-Credentials': 'true',
      });

      // Add Token Interceptor for automatic token refresh
      final tokenInterceptor = TokenInterceptor(_instance!._dio);
      _instance!._dio.interceptors.add(tokenInterceptor);

      // Add more robust error logging
      _instance!._dio.interceptors.add(
        dio_client.InterceptorsWrapper(
          onError: (dio_client.DioException e, dio_client.ErrorInterceptorHandler handler) {
            LoggerUtils.error(
              'API Request Error', 
              e, 
              e.stackTrace,
            );
            handler.next(e);
          },
        )
      );

      // Add interceptors in the correct order
      _instance!._dio.interceptors.addAll([
        AuthInterceptor(tokenManager),
        ErrorInterceptor(
          authService: authService,
          dialogService: dialogService,
        ),
        CacheInterceptor(
          cacheManager: cacheManager,
          maxAge: const Duration(hours: 1),
          cacheableMethods: const ['GET'],
        ),
        RateLimitInterceptor(),
      ]);

      // Add CORS interceptor
      _instance!._dio.interceptors.add(
        dio_client.InterceptorsWrapper(
          onRequest: (options, handler) {
            // Let the server handle CORS headers
            return handler.next(options);
          },
          onResponse: (response, handler) {
            return handler.next(response);
          },
          onError: (error, handler) async {
            if (error.response?.statusCode == 401) {
              // Handle unauthorized error
              final refreshToken = await tokenManager.getRefreshToken();
              if (refreshToken != null) {
                try {
                  final response = await _instance!._dio.post(
                    '/auth/token/refresh/',
                    data: {'refresh': refreshToken},
                  );

                  if (response.statusCode == 200) {
                    await tokenManager.setTokens(
                      accessToken: response.data['access'],
                      refreshToken: response.data['refresh'],
                    );
                    error.requestOptions.headers['Authorization'] = 'Bearer ${response.data['access']}';
                    
                    // Retry the original request
                    final options = dio_client.Options(
                      method: error.requestOptions.method,
                      headers: error.requestOptions.headers,
                    );
                    final retryResponse = await _instance!._dio.request(
                      error.requestOptions.path,
                      data: error.requestOptions.data,
                      queryParameters: error.requestOptions.queryParameters,
                      options: options,
                    );
                    
                    return handler.resolve(retryResponse);
                  }
                } catch (e) {
                  await tokenManager.clearTokens();
                  LoggerUtils.error('Token refresh failed', e);
                }
              }
            }
            return handler.next(error);
          },
        ),
      );
    }

    return _instance!;
  }

  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<void> setRequestInterceptor(
    dio_client.InterceptorSendCallback onRequest,
  ) async {
    _dio.interceptors.add(
      dio_client.InterceptorsWrapper(onRequest: onRequest),
    );
  }

  Future<int> getOfflineQueueSize() async {
    return _offlineQueue.queueSize;
  }

  Future<void> syncOfflineChanges() async {
    await _offlineQueue.processQueue();
  }

  Map<String, dynamic> getRequestMetrics() {
    return {
      'batchedRequests': _requestManager.batchedRequestCount,
      'averageResponseTimes': _metrics.map(
        (key, times) => MapEntry(
          key,
          times.isEmpty ? 0 : times.reduce((a, b) => a + b) ~/ times.length,
        ),
      ),
    };
  }

  Map<String, dynamic> getCacheMetrics() {
    final cacheInterceptor =
        _dio.interceptors.whereType<CacheInterceptor>().firstOrNull;

    return cacheInterceptor?.metrics ??
        {
          'hits': 0,
          'misses': 0,
          'size': 0,
        };
  }

  Future<void> setDioForTesting(dio_client.Dio dio) async {
    _dio = dio;
  }

  void addInterceptor(dio_client.Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  void removeInterceptor(dio_client.Interceptor interceptor) {
    _dio.interceptors.remove(interceptor);
  }

  void clearInterceptors() {
    _dio.interceptors.clear();
  }

  Map<String, List<int>> get metrics => _metrics;

  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  Future<void> processOfflineQueue() async {
    await _offlineQueue.processQueue();
  }

  Future<void> clearOfflineQueue() async {
    await _offlineQueue.clear();
  }

  Future<void> dispose() async {
    _dio.close();
    await _offlineQueue.dispose();
    await _cacheManager.emptyCache();
  }

  // Track request timing for metrics
  void _trackRequestTiming(String path, int milliseconds) {
    _metrics[path] ??= [];
    _metrics[path]!.add(milliseconds);

    // Keep only last 100 requests
    if (_metrics[path]!.length > 100) {
      _metrics[path]!.removeAt(0);
    }
  }

  // Get average response time for an endpoint
  Duration getAverageResponseTime(String path) {
    final times = _metrics[path];
    if (times == null || times.isEmpty) return Duration.zero;

    final avg = times.reduce((a, b) => a + b) / times.length;
    return Duration(milliseconds: avg.round());
  }

  // Generic GET request with offline support
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
    bool useCache = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options == null
            ? dio_client.Options(extra: {'no-cache': !useCache})
            : options.copyWith(extra: {
                'no-cache': !useCache,
                ...options.extra ?? {},
              }),
        cancelToken: cancelToken,
      );

      _trackRequestTiming(path, stopwatch.elapsedMilliseconds);
      return response.data as T;
    } catch (e) {
      if (e is dio_client.DioException &&
          e.type == dio_client.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'GET',
          path: path,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
        rethrow;
      }
      LoggerUtils.error('GET request failed: $path', e);
      rethrow;
    }
  }

  // Generic POST request with offline support
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      _trackRequestTiming(path, stopwatch.elapsedMilliseconds);
      return response.data as T;
    } catch (e) {
      if (e is dio_client.DioException &&
          e.type == dio_client.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'POST',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
        rethrow;
      }
      LoggerUtils.error('POST request failed: $path', e);
      rethrow;
    }
  }

  // Generic PUT request with offline support
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      _trackRequestTiming(path, stopwatch.elapsedMilliseconds);
      return response.data as T;
    } catch (e) {
      if (e is dio_client.DioException &&
          e.type == dio_client.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'PUT',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
        rethrow;
      }
      LoggerUtils.error('PUT request failed: $path', e);
      rethrow;
    }
  }

  // Generic DELETE request with offline support
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      _trackRequestTiming(path, stopwatch.elapsedMilliseconds);
      return response.data as T;
    } catch (e) {
      if (e is dio_client.DioException &&
          e.type == dio_client.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'DELETE',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
        rethrow;
      }
      LoggerUtils.error('DELETE request failed: $path', e);
      rethrow;
    }
  }

  // Generic PATCH request with offline support
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      _trackRequestTiming(path, stopwatch.elapsedMilliseconds);
      return response.data as T;
    } catch (e) {
      if (e is dio_client.DioException &&
          e.type == dio_client.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'PATCH',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
        rethrow;
      }
      LoggerUtils.error('PATCH request failed: $path', e);
      rethrow;
    }
  }

  // Upload file
  Future<T> uploadFile<T>(
    String path,
    String filePath, {
    Map<String, dynamic>? data,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
    dio_client.ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = dio_client.FormData.fromMap({
        'file': await dio_client.MultipartFile.fromFile(filePath),
        if (data != null) ...data,
      });

      final response = await _dio.post<T>(
        path,
        data: formData,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
      );
      return response.data as T;
    } catch (e) {
      LoggerUtils.error('File upload failed: $path', e);
      rethrow;
    }
  }

  // Download file
  Future<void> downloadFile(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
    dio_client.ProgressCallback? onReceiveProgress,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      LoggerUtils.error('File download failed: $path', e);
      rethrow;
    }
  }
}
