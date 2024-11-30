import 'dart:async';
import 'package:dio/dio.dart';

class RateLimitInterceptor extends Interceptor {
  final Duration _interval;
  final int _maxRequests;
  final Map<String, List<DateTime>> _requestTimestamps = {};
  final Map<String, Completer<void>> _queueCompleters = {};

  RateLimitInterceptor({
    Duration? interval,
    int? maxRequests,
  })  : _interval = interval ?? const Duration(seconds: 1),
        _maxRequests = maxRequests ?? 10;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final endpoint = '${options.method}:${options.path}';
    
    // Initialize timestamps list for endpoint if not exists
    _requestTimestamps[endpoint] ??= [];
    
    // Remove timestamps older than interval
    _requestTimestamps[endpoint]!.removeWhere(
      (timestamp) => DateTime.now().difference(timestamp) > _interval,
    );
    
    // Check if rate limit exceeded
    if (_requestTimestamps[endpoint]!.length >= _maxRequests) {
      // Wait for the oldest request to expire
      final oldestTimestamp = _requestTimestamps[endpoint]!.first;
      final waitTime = _interval - DateTime.now().difference(oldestTimestamp);
      
      if (waitTime > Duration.zero) {
        // Create a completer if none exists
        _queueCompleters[endpoint] ??= Completer<void>();
        
        // Wait for the current completer
        await _queueCompleters[endpoint]!.future;
        
        // Create new completer for next request
        _queueCompleters[endpoint] = Completer<void>();
        
        // Schedule completion
        Future.delayed(waitTime, () {
          _queueCompleters[endpoint]?.complete();
        });
      }
    }
    
    // Add current timestamp
    _requestTimestamps[endpoint]!.add(DateTime.now());
    
    // Add rate limit headers
    options.headers.addAll({
      'X-RateLimit-Limit': _maxRequests.toString(),
      'X-RateLimit-Remaining': 
          (_maxRequests - _requestTimestamps[endpoint]!.length).toString(),
      'X-RateLimit-Reset': 
          DateTime.now().add(_interval).millisecondsSinceEpoch.toString(),
    });
    
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final endpoint = '${response.requestOptions.method}:${response.requestOptions.path}';
    
    // Complete the queue for this endpoint if exists
    _queueCompleters[endpoint]?.complete();
    _queueCompleters.remove(endpoint);
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final endpoint = '${err.requestOptions.method}:${err.requestOptions.path}';
    
    // Complete the queue for this endpoint if exists
    _queueCompleters[endpoint]?.complete();
    _queueCompleters.remove(endpoint);
    
    handler.next(err);
  }
}
