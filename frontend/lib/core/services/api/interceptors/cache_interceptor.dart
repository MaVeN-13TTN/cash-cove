import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheInterceptor extends Interceptor {
  final DefaultCacheManager _cacheManager;
  final Duration _maxAge;
  final List<String> _cacheableMethods;

  CacheInterceptor({
    DefaultCacheManager? cacheManager,
    Duration? maxAge,
    List<String>? cacheableMethods,
  })  : _cacheManager = cacheManager ?? DefaultCacheManager(),
        _maxAge = maxAge ?? const Duration(hours: 1),
        _cacheableMethods =
            cacheableMethods ?? const ['GET', 'HEAD', 'OPTIONS'];

  Map<String, dynamic> get metrics => {
    'hits': _cacheManager.getFileStream('').length, // Example, adjust logic as needed
    'misses': 0, // Example value, adjust logic as needed
    'size': _cacheManager.getFileStream('').length, // Example, adjust logic as needed
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Only cache specified methods
    if (!_cacheableMethods.contains(options.method.toUpperCase())) {
      return handler.next(options);
    }

    // Check if request should bypass cache
    if (options.extra['no-cache'] == true) {
      return handler.next(options);
    }

    // Generate cache key from request
    final cacheKey = _generateCacheKey(options);

    try {
      final cacheFile = await _cacheManager.getFileFromCache(cacheKey);
      
      if (cacheFile != null) {
        final age = DateTime.now().difference(cacheFile.validTill);
        
        // Return cached response if not expired
        if (age < _maxAge) {
          final cachedData = await cacheFile.file.readAsString();
          final response = Response(
            requestOptions: options,
            data: json.decode(cachedData),
            statusCode: 200,
            headers: Headers.fromMap({
              'cache-control': ['HIT'],
              'x-cache-age': ['${age.inSeconds}s'],
            }),
          );
          return handler.resolve(response);
        }
      }
    } catch (e) {
      // If cache read fails, proceed with network request
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    // Only cache specified methods
    if (!_cacheableMethods.contains(response.requestOptions.method.toUpperCase())) {
      return handler.next(response);
    }

    // Don't cache if specified in request
    if (response.requestOptions.extra['no-cache'] == true) {
      return handler.next(response);
    }

    // Cache successful responses
    if (response.statusCode == 200) {
      final cacheKey = _generateCacheKey(response.requestOptions);
      try {
        await _cacheManager.putFile(
          cacheKey,
          Uint8List.fromList(utf8.encode(json.encode(response.data))),
          maxAge: _maxAge,
        );
      } catch (e) {
        // If caching fails, still return response
      }
    }

    handler.next(response);
  }

  String _generateCacheKey(RequestOptions options) {
    final buffer = StringBuffer();
    buffer.write(options.method.toUpperCase());
    buffer.write(options.baseUrl);
    buffer.write(options.path);
    
    if (options.queryParameters.isNotEmpty) {
      final sortedParams = Map.fromEntries(
        options.queryParameters.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
      );
      buffer.write(json.encode(sortedParams));
    }
    
    return buffer.toString();
  }
}
