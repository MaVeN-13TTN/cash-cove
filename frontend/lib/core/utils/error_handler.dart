import 'package:dio/dio.dart';

class ErrorHandler {
  static String handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Connection timeout. Please check your internet connection.';
        case DioExceptionType.sendTimeout:
          return 'Send timeout. Please try again.';
        case DioExceptionType.receiveTimeout:
          return 'Receive timeout. Please try again.';
        case DioExceptionType.badResponse:
          return _handleResponseError(error.response);
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        case DioExceptionType.connectionError:
          return 'Network connection error. Please check your internet.';
        case DioExceptionType.unknown:
          return 'An unexpected error occurred.';
        case DioExceptionType.badCertificate:
          return 'SSL certificate validation failed. Please check your network connection.';
        default:
          return 'Unhandled network error. Please try again later.';
      }
    }
    
    return error.toString();
  }

  static String _handleResponseError(Response? response) {
    if (response == null) return 'No response from server.';

    switch (response.statusCode) {
      case 400:
        return response.data?['message'] ?? 'Bad request. Please check your input.';
      case 401:
        return 'Unauthorized. Please log in again.';
      case 403:
        return 'Forbidden. You do not have permission.';
      case 404:
        return 'Resource not found.';
      case 500:
        return 'Internal server error. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      default:
        return response.data?['message'] ?? 'An error occurred. Status code: ${response.statusCode}';
    }
  }
}
