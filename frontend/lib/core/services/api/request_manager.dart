import 'dart:async';
import 'dart:collection';
import 'package:dio/dio.dart';
import '../../utils/logger_utils.dart';

enum RequestPriority {
  high,
  medium,
  low,
}

class BatchRequest {
  final String endpoint;
  final String method;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final RequestPriority priority;
  final Completer<Response> completer;
  final DateTime createdAt;
  final Options? options;

  BatchRequest({
    required this.endpoint,
    required this.method,
    this.data,
    this.queryParameters,
    this.priority = RequestPriority.medium,
    this.options,
  })  : completer = Completer<Response>(),
        createdAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'method': method,
    'data': data,
    'queryParameters': queryParameters,
    'headers': options?.headers,
  };
}

class RequestManager {
  final Dio _dio;
  final Duration batchWindow;
  final int maxBatchSize;
  
  late final Queue<BatchRequest> _requestQueue = Queue<BatchRequest>();
  
  int _compareBatchRequests(BatchRequest a, BatchRequest b) {
    // First compare by priority (descending order)
    final priorityComparison = a.priority.index.compareTo(b.priority.index);
    if (priorityComparison != 0) return priorityComparison;
    
    // Then by creation time (FIFO)
    return a.createdAt.compareTo(b.createdAt);
  }
  
  void _sortQueue() {
    final List<BatchRequest> sortedList = _requestQueue.toList()
      ..sort(_compareBatchRequests);
    _requestQueue.clear();
    _requestQueue.addAll(sortedList);
  }
  
  Timer? _batchTimer;
  bool _isProcessing = false;
  int _batchedRequestCount = 0;
  final _metrics = <String, List<int>>{};

  int get queueSize => _requestQueue.length;
  int get batchedRequestCount => _batchedRequestCount;
  Map<String, List<int>> get metrics => Map.unmodifiable(_metrics);

  RequestManager({
    required Dio dio,
    this.batchWindow = const Duration(milliseconds: 50),
    this.maxBatchSize = 10,
  }) : _dio = dio;

  Future<Response> scheduleRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    RequestPriority priority = RequestPriority.medium,
    Options? options,
  }) {
    final request = BatchRequest(
      endpoint: endpoint,
      method: method,
      data: data,
      queryParameters: queryParameters,
      priority: priority,
      options: options,
    );

    _requestQueue.add(request);
    _sortQueue();
    _scheduleBatchProcessing();

    return request.completer.future;
  }

  void _scheduleBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = Timer(batchWindow, _processBatch);
  }

  Future<void> _processBatch() async {
    if (_isProcessing || _requestQueue.isEmpty) return;
    
    _isProcessing = true;
    final batch = <BatchRequest>[];
    final stopwatch = Stopwatch()..start();
    
    try {
      // Collect requests for this batch
      while (_requestQueue.isNotEmpty && batch.length < maxBatchSize) {
        batch.add(_requestQueue.removeFirst());
      }

      // Process GET requests individually (they can't be batched)
      final getFutures = batch
          .where((req) => req.method.toUpperCase() == 'GET')
          .map(_processGetRequest);

      // Batch other requests
      final batchableRequests = batch
          .where((req) => req.method.toUpperCase() != 'GET')
          .toList();

      if (batchableRequests.isNotEmpty) {
        await _processBatchableRequests(batchableRequests);
        _batchedRequestCount += batchableRequests.length;
      }

      // Wait for GET requests to complete and increment batched request count
      await Future.wait(getFutures);
      _batchedRequestCount += getFutures.length;
      
      // Track metrics
      final processingTime = stopwatch.elapsedMilliseconds;
      _metrics['batchProcessing'] ??= [];
      _metrics['batchProcessing']!.add(processingTime);
      
      if (_metrics['batchProcessing']!.length > 100) {
        _metrics['batchProcessing']!.removeAt(0);
      }
      
    } catch (e, stackTrace) {
      LoggerUtils.error('Error processing batch', e, stackTrace);
      // Complete all requests with error
      for (final request in batch) {
        if (!request.completer.isCompleted) {
          request.completer.completeError(e);
        }
      }
    } finally {
      _isProcessing = false;
      if (_requestQueue.isNotEmpty) {
        _scheduleBatchProcessing();
      }
    }
  }

  Future<void> _processGetRequest(BatchRequest request) async {
    try {
      final response = await _dio.get(
        request.endpoint,
        queryParameters: request.queryParameters,
        options: request.options,
      );
      request.completer.complete(response);
    } catch (e) {
      request.completer.completeError(e);
    }
  }

  Future<void> _processBatchableRequests(List<BatchRequest> requests) async {
    if (requests.isEmpty) return;

    final batchData = requests.map((req) => req.toJson()).toList();
    
    try {
      final response = await _dio.post(
        '/batch',
        data: {'requests': batchData},
      );

      // Process batch response
      final responses = response.data['responses'] as List;
      for (var i = 0; i < requests.length; i++) {
        final request = requests[i];
        final responseData = responses[i];
        
        if (responseData['error'] != null) {
          request.completer.completeError(DioException(
            requestOptions: RequestOptions(path: request.endpoint),
            error: responseData['error'],
          ));
        } else {
          request.completer.complete(Response(
            requestOptions: RequestOptions(path: request.endpoint),
            data: responseData['data'],
            statusCode: responseData['status'],
            headers: Headers.fromMap(responseData['headers'] ?? {}),
          ));
        }
      }
    } catch (e) {
      // If batch request fails, complete all requests with error
      for (final request in requests) {
        request.completer.completeError(e);
      }
    }
  }

  Map<String, dynamic> getMetrics() {
    final avgProcessingTime = _metrics['batchProcessing']?.isEmpty ?? true
        ? 0
        : _metrics['batchProcessing']!.reduce((a, b) => a + b) /
            _metrics['batchProcessing']!.length;

    return {
      'queueSize': queueSize,
      'batchedRequestCount': _batchedRequestCount,
      'averageProcessingTime': avgProcessingTime,
      'isProcessing': _isProcessing,
    };
  }

  void clearMetrics() {
    _metrics.clear();
    _batchedRequestCount = 0;
  }

  void dispose() {
    _batchTimer?.cancel();
    _requestQueue.clear();
    clearMetrics();
  }
}
