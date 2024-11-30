import 'dart:async';
import 'package:dio/dio.dart';
import '../../utils/logger_utils.dart';

enum CircuitState {
  closed,    // Normal operation
  open,      // Failing, reject requests
  halfOpen,  // Testing if service is back
}

class CircuitBreaker {
  final int failureThreshold;
  final Duration resetTimeout;
  final Duration halfOpenTimeout;
  
  CircuitState _currentState = CircuitState.closed;
  int _failureCount = 0;
  Timer? _resetTimer;
  DateTime? _lastStateChange;
  
  final _stateController = StreamController<CircuitState>.broadcast();
  
  Stream<CircuitState> get stateStream => _stateController.stream;
  CircuitState get currentState => _currentState;
  int get failureCount => _failureCount;
  DateTime? get lastStateChange => _lastStateChange;
  Duration get timeInCurrentState => 
      _lastStateChange == null ? Duration.zero : DateTime.now().difference(_lastStateChange!);

  CircuitBreaker({
    this.failureThreshold = 5,
    this.resetTimeout = const Duration(seconds: 60),
    this.halfOpenTimeout = const Duration(seconds: 30),
  });

  Future<T> execute<T>(Future<T> Function() request) async {
    if (_shouldRejectRequest()) {
      throw CircuitBreakerException(
        'Circuit breaker is ${_currentState.name}',
        _currentState,
      );
    }

    try {
      final response = await request();
      _onSuccess();
      return response;
    } catch (error) {
      _onError(error);
      rethrow;
    }
  }

  bool _shouldRejectRequest() {
    if (_currentState == CircuitState.open) {
      final timeSinceLastStateChange = DateTime.now().difference(_lastStateChange!);
      if (timeSinceLastStateChange >= resetTimeout) {
        _transitionTo(CircuitState.halfOpen);
        return false;
      }
      return true;
    }
    return false;
  }

  void _onSuccess() {
    if (_currentState == CircuitState.halfOpen) {
      _transitionTo(CircuitState.closed);
    }
    _failureCount = 0;
  }

  void _onError(dynamic error) {
    if (_currentState == CircuitState.closed) {
      _failureCount++;
      if (_failureCount >= failureThreshold) {
        _transitionTo(CircuitState.open);
      }
    } else if (_currentState == CircuitState.halfOpen) {
      _transitionTo(CircuitState.open);
    }
  }

  void _transitionTo(CircuitState newState) {
    _currentState = newState;
    _lastStateChange = DateTime.now();
    _stateController.add(newState);
    
    _resetTimer?.cancel();
    if (newState == CircuitState.open) {
      _resetTimer = Timer(resetTimeout, () {
        if (_currentState == CircuitState.open) {
          _transitionTo(CircuitState.halfOpen);
        }
      });
    }
    
    LoggerUtils.info('Circuit breaker transitioned to ${newState.name}');
  }

  void reset() {
    _failureCount = 0;
    _transitionTo(CircuitState.closed);
  }

  void dispose() {
    _resetTimer?.cancel();
    _stateController.close();
  }

  Map<String, dynamic> getMetrics() {
    return {
      'state': _currentState.name,
      'failureCount': _failureCount,
      'timeInCurrentState': timeInCurrentState.inSeconds,
      'failureThreshold': failureThreshold,
      'resetTimeout': resetTimeout.inSeconds,
    };
  }
}

class CircuitBreakerException implements Exception {
  final String message;
  final CircuitState state;

  CircuitBreakerException(this.message, this.state);

  @override
  String toString() => 'CircuitBreakerException: $message (State: ${state.name})';
}

class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffFactor;
  int _retryCount = 0;
  final Dio _dio;

  RetryInterceptor({
    required this.maxRetries,
    required this.initialDelay,
    required this.backoffFactor,
    required Dio dio,
  }) : _dio = dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err) && _retryCount < maxRetries) {
      _retryCount++;
      final delay = _calculateDelay();
      
      LoggerUtils.info(
        'Retrying request ($_retryCount/$maxRetries) after ${delay.inSeconds}s',
      );
      
      await Future.delayed(delay);
      try {
        final options = err.requestOptions;
        final response = await _dio.request(
          options.path,
          data: options.data,
          queryParameters: options.queryParameters,
          options: Options(
            method: options.method,
            headers: options.headers,
            contentType: options.contentType,
            responseType: options.responseType,
            validateStatus: options.validateStatus,
          ),
        );
        return handler.resolve(response);
      } catch (e) {
        return handler.next(err);
      }
    }
    return handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionError ||
           err.type == DioExceptionType.receiveTimeout ||
           err.response?.statusCode == 503;
  }

  Duration _calculateDelay() {
    return initialDelay * (backoffFactor * _retryCount);
  }
}
