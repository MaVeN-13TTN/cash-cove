import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:flutter/material.dart';

class ErrorService extends GetxService {
  void handleError(dynamic error, {String? customMessage}) {
    String message = customMessage ?? 'An error occurred';
    
    if (error is DioException) {
      message = _handleDioError(error);
    } else if (error is TypeError) {
      message = 'Data type error occurred';
    } else if (error is FormatException) {
      message = 'Invalid data format';
    }

    _showErrorSnackbar(message);
  }

  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timed out';
      case DioExceptionType.sendTimeout:
        return 'Request timed out';
      case DioExceptionType.receiveTimeout:
        return 'Response timed out';
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.cancel:
        return 'Request cancelled';
      case DioExceptionType.unknown:
        if (error.error != null && error.error.toString().contains('SocketException')) {
          return 'No internet connection';
        }
        return 'Unknown error occurred';
      default:
        return 'Network error occurred';
    }
  }

  String _handleBadResponse(Response? response) {
    if (response == null) return 'Server error occurred';

    switch (response.statusCode) {
      case 400:
        return _parseErrorMessage(response.data) ?? 'Invalid request';
      case 401:
        return 'Unauthorized access';
      case 403:
        return 'Access forbidden';
      case 404:
        return 'Resource not found';
      case 422:
        return _parseValidationErrors(response.data) ?? 'Validation error';
      case 429:
        return 'Too many requests. Please try again later';
      case 500:
        return 'Server error occurred';
      default:
        return 'Server error occurred';
    }
  }

  String? _parseErrorMessage(dynamic data) {
    if (data == null) return null;
    
    if (data is Map) {
      if (data.containsKey('message')) {
        return data['message'];
      } else if (data.containsKey('error')) {
        return data['error'];
      } else if (data.containsKey('detail')) {
        return data['detail'];
      }
    }
    
    return null;
  }

  String? _parseValidationErrors(dynamic data) {
    if (data == null || data is! Map) return null;

    final List<String> errors = [];
    
    data.forEach((key, value) {
      if (value is List) {
        errors.add('$key: ${value.join(', ')}');
      } else if (value is String) {
        errors.add('$key: $value');
      }
    });

    return errors.isNotEmpty ? errors.join('\n') : null;
  }

  void _showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
