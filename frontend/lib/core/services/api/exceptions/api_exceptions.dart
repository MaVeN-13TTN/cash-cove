import 'package:dio/dio.dart';

/// Base class for all API exceptions
class ApiException implements Exception {
  final RequestOptions requestOptions;
  final String message;

  const ApiException({
    required this.requestOptions,
    required this.message,
  });

  @override
  String toString() => message;
}

/// Thrown when API request times out
class ApiTimeoutException extends ApiException {
  ApiTimeoutException(RequestOptions requestOptions)
      : super(
          requestOptions: requestOptions,
          message: 'Connection timeout',
        );
}

/// Thrown when API returns 400
class ApiBadRequestException extends ApiException {
  ApiBadRequestException({
    required super.requestOptions,
    required super.message,
  });
}

/// Thrown when API returns 401
class ApiUnauthorizedException extends ApiException {
  ApiUnauthorizedException({
    required super.requestOptions,
    required super.message,
  });
}

/// Thrown when API returns 403
class ApiForbiddenException extends ApiException {
  ApiForbiddenException({
    required super.requestOptions,
    required super.message,
  });
}

/// Thrown when API returns 404
class ApiNotFoundException extends ApiException {
  ApiNotFoundException({
    required super.requestOptions,
    required super.message,
  });
}

/// Thrown when API returns 409
class ApiConflictException extends ApiException {
  ApiConflictException({
    required super.requestOptions,
    required super.message,
  });
}

/// Thrown when API returns 422
class ApiUnprocessableEntityException extends ApiException {
  ApiUnprocessableEntityException({
    required super.requestOptions,
    required super.message,
  });
}

/// Thrown when API returns 500
class ApiServerException extends ApiException {
  ApiServerException({
    required super.requestOptions,
    required super.message,
  });
}

/// Thrown when request is cancelled
class ApiCancelledException extends ApiException {
  ApiCancelledException(RequestOptions requestOptions)
      : super(
          requestOptions: requestOptions,
          message: 'Request cancelled',
        );
}

/// Thrown when there is no internet connection
class ApiNoInternetException extends ApiException {
  ApiNoInternetException(RequestOptions requestOptions)
      : super(
          requestOptions: requestOptions,
          message: 'No internet connection',
        );
}
