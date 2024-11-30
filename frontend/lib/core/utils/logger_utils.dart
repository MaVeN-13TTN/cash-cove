import 'dart:developer' as developer;

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class LoggerUtils {
  static bool _isDebugMode = true;
  static const String _tag = 'BudgetTracker';

  static void setDebugMode(bool isDebug) {
    _isDebugMode = isDebug;
  }

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (!_isDebugMode && level == LogLevel.debug) return;

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.toString().split('.').last.toUpperCase();
    final logMessage = '[$timestamp] $levelStr: $message';

    if (error != null) {
      final errorMessage = '\nError: $error';
      final stackMessage = stackTrace != null ? '\nStack Trace:\n$stackTrace' : '';
      developer.log(
        '$logMessage$errorMessage$stackMessage',
        name: _tag,
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      developer.log(
        logMessage,
        name: _tag,
        level: _getLevelValue(level),
      );
    }
  }

  static int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }

  static void logHttpRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!_isDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('HTTP Request:');
    buffer.writeln('$method $url');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('Headers:');
      headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (body != null) {
      buffer.writeln('Body:');
      buffer.writeln('  $body');
    }

    debug(buffer.toString());
  }

  static void logHttpResponse(
    int statusCode,
    String url, {
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (!_isDebugMode) return;

    final buffer = StringBuffer();
    buffer.writeln('HTTP Response:');
    buffer.writeln('$statusCode $url');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('Headers:');
      headers.forEach((key, value) {
        buffer.writeln('  $key: $value');
      });
    }

    if (body != null) {
      buffer.writeln('Body:');
      buffer.writeln('  $body');
    }

    debug(buffer.toString());
  }
}
