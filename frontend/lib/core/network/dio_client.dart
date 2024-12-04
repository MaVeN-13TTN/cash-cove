import 'package:dio/dio.dart' as dio_client;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import '../services/api/interceptors/auth_interceptor.dart';
import '../services/api/interceptors/error_interceptor.dart';
import '../services/api/interceptors/cache_interceptor.dart';
import '../services/api/interceptors/rate_limit_interceptor.dart';
import '../services/storage/secure_storage.dart';
import '../services/auth/auth_service.dart';
import '../services/auth/token_manager.dart';
import '../widgets/dialogs/dialog_service.dart';
import 'interceptors/trailing_slash_interceptor.dart';

class DioClient extends GetxService {
  late dio_client.Dio _dio;
  dio_client.Dio get dio => _dio;
  String get baseUrl => _dio.options.baseUrl;

  static DioClient? _instance;

  DioClient._internal();

  static Future<DioClient> initialize({
    required String baseUrl,
    required TokenManager tokenManager,
    dio_client.Dio? testDio,
  }) async {
    if (_instance == null) {
      final storage = await SecureStorage.initialize();
      final cacheManager = DefaultCacheManager();
      final authService = Get.find<AuthService>();
      final dialogService = Get.find<DialogService>();

      _instance = DioClient._internal();
      _instance!._dio = testDio ?? dio_client.Dio(
        dio_client.BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Credentials': 'true',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      // Add interceptors in the correct order
      _instance!._dio.interceptors.addAll([
        TrailingSlashInterceptor(),
        AuthInterceptor(storage),
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
    }

    return _instance!;
  }

  // Compatibility methods with existing ApiClient
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  Future<void> setRequestInterceptor(dio_client.InterceptorSendCallback onRequest) async {
    _dio.interceptors.add(
      dio_client.InterceptorsWrapper(onRequest: onRequest),
    );
  }

  void _handleError(dio_client.DioException error) {
    // Use DialogService's existing method
    final dialogService = Get.find<DialogService>();
    dialogService.showError(
      title: 'Network Error', 
      message: error.message ?? 'An unexpected error occurred',
    );
  }

  // Helper methods for different HTTP methods
  Future<dio_client.Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on dio_client.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio_client.Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on dio_client.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio_client.Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on dio_client.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  Future<dio_client.Response> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
    dio_client.Options? options,
    dio_client.CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on dio_client.DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
}
