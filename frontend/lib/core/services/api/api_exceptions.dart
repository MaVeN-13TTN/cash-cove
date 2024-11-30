class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (Status Code: $statusCode)';
}

class RateLimitExceededException extends ApiException {
  final int? retryAfter;

  RateLimitExceededException(String message, {this.retryAfter, int? statusCode})
      : super(message, statusCode);
}

class ValidationException extends ApiException {
  final Map<String, dynamic>? errors;

  ValidationException(String message, {this.errors, int? statusCode})
      : super(message, statusCode);
}
