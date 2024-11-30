import 'package:dio/dio.dart';
import '../../../utils/logger_utils.dart';
import '../exceptions/api_exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    LoggerUtils.error(
      'API Error: ${err.requestOptions.path}',
      err.response?.data ?? err.message,
    );

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        throw ApiTimeoutException(err.requestOptions);

      case DioExceptionType.badResponse:
        switch (err.response?.statusCode) {
          case 400:
            throw ApiBadRequestException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Bad request',
            );
          case 401:
            throw ApiUnauthorizedException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Unauthorized',
            );
          case 403:
            throw ApiForbiddenException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Forbidden',
            );
          case 404:
            throw ApiNotFoundException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Not found',
            );
          case 409:
            throw ApiConflictException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Conflict',
            );
          case 422:
            throw ApiUnprocessableEntityException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Unprocessable Entity',
            );
          case 500:
            throw ApiServerException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Internal server error',
            );
          default:
            throw ApiException(
              requestOptions: err.requestOptions,
              message: err.response?.data?['message'] ?? 'Unknown error occurred',
            );
        }

      case DioExceptionType.cancel:
        throw ApiCancelledException(err.requestOptions);

      case DioExceptionType.unknown:
        if (err.error != null &&
            err.error.toString().contains('SocketException')) {
          throw ApiNoInternetException(err.requestOptions);
        }
        throw ApiException(
          requestOptions: err.requestOptions,
          message: err.response?.data?['message'] ?? 'Unknown error occurred',
        );

      default:
        throw ApiException(
          requestOptions: err.requestOptions,
          message: err.response?.data?['message'] ?? 'Unknown error occurred',
        );
    }
  }
}
