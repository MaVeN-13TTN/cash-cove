import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

class PerformanceMetric {
  final String name;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  PerformanceMetric({
    required this.name,
    required this.duration,
    required this.timestamp,
    this.metadata,
  });
}

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;

  final _metricsController = BehaviorSubject<PerformanceMetric>();
  final Map<String, Stopwatch> _activeMetrics = {};

  Stream<PerformanceMetric> get metrics => _metricsController.stream;

  PerformanceMonitor._internal();

  void startMetric(String name) {
    if (_activeMetrics.containsKey(name)) {
      debugPrint('Warning: Metric $name is already being tracked');
      return;
    }
    
    final stopwatch = Stopwatch()..start();
    _activeMetrics[name] = stopwatch;
  }

  void endMetric(String name, {Map<String, dynamic>? metadata}) {
    final stopwatch = _activeMetrics.remove(name);
    if (stopwatch == null) {
      debugPrint('Warning: No active metric found for $name');
      return;
    }

    stopwatch.stop();
    final metric = PerformanceMetric(
      name: name,
      duration: stopwatch.elapsed,
      timestamp: DateTime.now(),
      metadata: metadata,
    );

    _metricsController.add(metric);
    
    // Log slow operations
    if (stopwatch.elapsed.inMilliseconds > 100) {
      debugPrint('Slow operation detected: $name took ${stopwatch.elapsed.inMilliseconds}ms');
    }
  }

  void trackApiCall(String endpoint, Future<dynamic> Function() apiCall) async {
    final metricName = 'api_call_$endpoint';
    startMetric(metricName);
    
    try {
      await apiCall();
    } finally {
      endMetric(metricName, metadata: {'endpoint': endpoint});
    }
  }

  void trackWebSocketMessage(String type, void Function() handler) {
    final metricName = 'ws_message_$type';
    startMetric(metricName);
    
    try {
      handler();
    } finally {
      endMetric(metricName, metadata: {'message_type': type});
    }
  }

  void dispose() {
    _metricsController.close();
  }
}
