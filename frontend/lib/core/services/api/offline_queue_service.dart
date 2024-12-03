import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../utils/logger_utils.dart';

class QueuedRequest {
  final String method;
  final String path;
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? queryParameters;
  final Map<String, dynamic>? headers;
  final DateTime timestamp;

  QueuedRequest({
    required this.method,
    required this.path,
    this.data,
    this.queryParameters,
    this.headers,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'method': method,
    'path': path,
    'data': data,
    'queryParameters': queryParameters,
    'headers': headers,
    'timestamp': timestamp.toIso8601String(),
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    method: json['method'],
    path: json['path'],
    data: json['data'],
    queryParameters: json['queryParameters'],
    headers: json['headers'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class OfflineQueueService {
  static const String _boxName = 'offline_requests';
  final Dio _dio;
  final Box<String> _box;
  final _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isProcessing = false;
  final _processingCompleter = Completer<void>();

  OfflineQueueService({
    required Dio dio,
    required Box<String> box,
  })  : _dio = dio,
        _box = box {
    _initConnectivityListener();
  }

  static Future<OfflineQueueService> init(Dio dio) async {
    final box = await Hive.openBox<String>(_boxName);
    return OfflineQueueService(dio: dio, box: box);
  }

  void _initConnectivityListener() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        processQueue();
      }
    });
  }

  bool get isProcessing => _isProcessing;

  int get queueSize => _box.length;

  Future<void> enqueueRequest(QueuedRequest request) async {
    try {
      await _box.add(json.encode(request.toJson()));
      LoggerUtils.info('Request enqueued: ${request.method} ${request.path}');
    } catch (e, stackTrace) {
      LoggerUtils.error('Failed to enqueue request', e, stackTrace);
    }
  }

  Future<void> processQueue() async {
    if (_isProcessing) {
      await _processingCompleter.future;
      return;
    }

    _isProcessing = true;
    final completer = Completer<void>();
    _processingCompleter.complete(completer.future);

    try {
      final keys = _box.keys.toList()
        ..sort(); // Process oldest requests first

      for (final key in keys) {
        if (await _connectivity.checkConnectivity() == ConnectivityResult.none) {
          break;
        }

        final requestJson = _box.get(key);
        if (requestJson == null) continue;

        try {
          final request = QueuedRequest.fromJson(json.decode(requestJson));
          
          // Skip requests older than 24 hours
          if (DateTime.now().difference(request.timestamp) > const Duration(hours: 24)) {
            await _box.delete(key);
            continue;
          }

          await _dio.request(
            request.path,
            data: request.data,
            queryParameters: request.queryParameters,
            options: Options(
              method: request.method,
              headers: request.headers,
            ),
          );

          await _box.delete(key);
          LoggerUtils.debug('Processed queued request: ${request.path}');
        } catch (e, stackTrace) {
          LoggerUtils.error('Failed to process queued request', e, stackTrace);
          // Leave failed request in queue for retry
          continue;
        }
      }
    } finally {
      _isProcessing = false;
      completer.complete();
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _box.close();
  }

  /// Clears all pending requests from the queue
  Future<void> clear() async {
    final keys = _box.keys.toList();
    for (final key in keys) {
      await _box.delete(key);
    }
    LoggerUtils.info('Offline queue cleared: ${keys.length} requests removed');
  }
}
