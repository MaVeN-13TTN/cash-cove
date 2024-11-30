import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../utils/logger_utils.dart'; // Corrected import path

/// Service responsible for tracking analytics events and user behavior
class AnalyticsService extends GetxService {
  static AnalyticsService get instance => Get.find<AnalyticsService>();

  final RxBool _isInitialized = false.obs;
  Timer? _batchTimer;
  final List<Map<String, dynamic>> _eventQueue = [];
  final Duration _batchInterval = const Duration(seconds: 30);

  bool get isInitialized => _isInitialized.value;

  @override
  void onInit() {
    super.onInit();
    initialize();
  }

  Future<void> initialize() async {
    if (!_isInitialized.value) {
      try {
        // Add initialization logic here (e.g., setting up API keys)
        _isInitialized.value = true;
        _startBatchProcessing();
      } catch (e) {
        LoggerUtils.error('Failed to initialize AnalyticsService: $e');
        _isInitialized.value = false;
      }
    }
  }

  /// Track a custom event with optional parameters
  void trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    _eventQueue.add({'event': eventName, 'parameters': parameters});
  }

  /// Process batch of events
  Future<void> _processBatch() async {
    if (_eventQueue.isEmpty) return;

    try {
      final batch = List<Map<String, dynamic>>.from(_eventQueue);
      _eventQueue.clear();

      // Implement actual analytics API call
      try {
        final response = await Dio().post(
          'https://your-backend-url.com/api/analytics/', // Replace with actual endpoint
          data: batch,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer your_token', // Replace with actual token
            },
          ),
        );

        if (response.statusCode == 200) {
          LoggerUtils.info('Analytics batch processed successfully');
        } else {
          LoggerUtils.error('Failed to process analytics batch: ${response.statusCode}');
        }
      } catch (e) {
        LoggerUtils.error('Error sending analytics batch', e);
      }

      if (kDebugMode) {
        LoggerUtils.debug('Processing analytics batch: $batch');
      }
    } catch (e) {
      LoggerUtils.error('Failed to process analytics batch', e);
      // Re-add events to queue on failure
      _eventQueue.addAll(_eventQueue);
    }
  }

  /// Start batch processing timer
  void _startBatchProcessing() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (timer) {
      _processBatch();
    });
  }

  /// Get current event queue (for testing/debugging)
  List<Map<String, dynamic>> get eventQueue => List.from(_eventQueue);

  /// Clear event queue (for testing/debugging)
  void clearQueue() => _eventQueue.clear();
}