import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import '../storage/secure_storage.dart';
import '../../utils/logger_utils.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/cache_interceptor.dart';
import 'interceptors/rate_limit_interceptor.dart';
import 'offline_queue_service.dart';
import 'request_manager.dart';
import '../auth/token_manager.dart';
import 'package:meta/meta.dart';

class ApiClient extends GetxService {
  late dio.Dio _dio;
  late final OfflineQueueService _offlineQueue;
  late RequestManager _requestManager;
  final SecureStorage _storage;
  final _metrics = <String, List<int>>{};
  static ApiClient? _instance;

  ApiClient._({required SecureStorage storage}) : _storage = storage {
    _dio = dio.Dio(
      dio.BaseOptions(
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _requestManager = RequestManager(dio: _dio);
  }

  static ApiClient get instance {
    if (_instance == null) {
      throw StateError('ApiClient must be initialized first. Call ApiClient.initialize()');
    }
    return _instance!;
  }

  static Future<ApiClient> initialize({
    required String baseUrl,
    required TokenManager tokenManager,
    dio.Dio? testDio,
  }) async {
    if (_instance == null) {
      final storage = await SecureStorage.initialize();
      _instance = ApiClient._(
        storage: storage,
      );
      await _instance!._initOfflineQueue();
      if (testDio == null) {
        _instance!._setupInterceptors();
      }
      _instance!._dio.options.baseUrl = baseUrl;
      Get.put(_instance!);
    }
    return _instance!;
  }

  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<void> setRequestInterceptor(
    dio.InterceptorSendCallback onRequest,
  ) async {
    _dio.interceptors.add(
      dio.InterceptorsWrapper(onRequest: onRequest),
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

  Future<void> _initOfflineQueue() async {
    _offlineQueue = await OfflineQueueService.init(_dio);
  }

  void _setupInterceptors() {
    // Add logging interceptor in debug mode
    _dio.interceptors.add(dio.LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => LoggerUtils.debug('API: $object'),
    ));

    // Add auth interceptor
    _dio.interceptors.add(AuthInterceptor(_storage));

    // Add cache interceptor
    _dio.interceptors.add(CacheInterceptor(
      maxAge: const Duration(minutes: 30),
      cacheableMethods: const ['GET'],
    ));

    // Add rate limit interceptor
    _dio.interceptors.add(RateLimitInterceptor(
      interval: const Duration(seconds: 1),
      maxRequests: 10,
    ));

    // Add error interceptor
    _dio.interceptors.add(ErrorInterceptor());
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
    dio.Options? options,
    dio.CancelToken? cancelToken,
    bool useCache = true,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options == null
            ? dio.Options(extra: {'no-cache': !useCache})
            : options.copyWith(extra: {
                'no-cache': !useCache,
                ...options.extra ?? {},
              }),
        cancelToken: cancelToken,
      );

      _trackRequestTiming(path, stopwatch.elapsedMilliseconds);
      return response.data as T;
    } catch (e) {
      if (e is dio.DioException &&
          e.type == dio.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'GET',
          path: path,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
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
    dio.Options? options,
    dio.CancelToken? cancelToken,
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
      if (e is dio.DioException &&
          e.type == dio.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'POST',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
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
    dio.Options? options,
    dio.CancelToken? cancelToken,
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
      if (e is dio.DioException &&
          e.type == dio.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'PUT',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
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
    dio.Options? options,
    dio.CancelToken? cancelToken,
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
      if (e is dio.DioException &&
          e.type == dio.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'DELETE',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
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
    dio.Options? options,
    dio.CancelToken? cancelToken,
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
      if (e is dio.DioException &&
          e.type == dio.DioExceptionType.connectionError) {
        // Queue request for offline processing
        await _offlineQueue.enqueueRequest(QueuedRequest(
          method: 'PATCH',
          path: path,
          data: data,
          queryParameters: queryParameters,
          headers: options?.headers,
        ));
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
    dio.Options? options,
    dio.CancelToken? cancelToken,
    dio.ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = dio.FormData.fromMap({
        'file': await dio.MultipartFile.fromFile(filePath),
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
    dio.Options? options,
    dio.CancelToken? cancelToken,
    dio.ProgressCallback? onReceiveProgress,
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

  // Method to set Dio instance for testing purposes
  @visibleForTesting
  void setDioForTesting(dio.Dio testDio) {
    _dio = testDio;
    _requestManager = RequestManager(dio: _dio);
  }

  // Dispose resources
  Future<void> dispose() async {
    await _offlineQueue.dispose();
    _dio.close();
  }
}
