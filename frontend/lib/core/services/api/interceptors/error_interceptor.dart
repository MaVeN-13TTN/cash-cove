import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';
import '../../../widgets/dialogs/dialog_service.dart';

class ErrorCodes {
  static const int authError = 1000;
  static const int validationError = 2000;
  static const int notFound = 3000;
  static const int permissionDenied = 4000;
  static const int serverError = 5000;
}

class ErrorInterceptor extends Interceptor {
  final AuthService _authService;
  final DialogService _dialogService;

  ErrorInterceptor({
    required AuthService authService, 
    required DialogService dialogService,
  }) : _authService = authService, 
       _dialogService = dialogService;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.data != null && err.response?.data['error'] != null) {
      final errorData = err.response?.data['error'];
      final errorCode = errorData['code'];
      
      switch (errorCode) {
        case ErrorCodes.authError:
          _handleAuthError(err);
          break;
        case ErrorCodes.validationError:
          _handleValidationError(err, errorData['details']);
          break;
        case ErrorCodes.notFound:
          _handleNotFoundError(err);
          break;
        case ErrorCodes.permissionDenied:
          _handlePermissionError(err);
          break;
        case ErrorCodes.serverError:
          _handleServerError(err);
          break;
        default:
          _handleUnknownError(err);
      }
    }
    
    handler.next(err);
  }

  void _handleAuthError(DioException err) {
    _authService.handleAuthError();
  }

  void _handleValidationError(DioException err, Map<String, dynamic> details) {
    _dialogService.showError(
      title: 'Validation Error',
      message: _formatValidationErrors(details),
    );
  }

  void _handleNotFoundError(DioException err) {
    _dialogService.showError(
      title: 'Not Found',
      message: 'The requested resource was not found.',
    );
  }

  void _handlePermissionError(DioException err) {
    _dialogService.showError(
      title: 'Permission Denied',
      message: 'You do not have permission to perform this action.',
    );
  }

  void _handleServerError(DioException err) {
    _dialogService.showError(
      title: 'Server Error',
      message: 'An unexpected error occurred. Please try again later.',
    );
  }

  void _handleUnknownError(DioException err) {
    _dialogService.showError(
      title: 'Error',
      message: 'An unexpected error occurred. Please try again.',
    );
  }

  String _formatValidationErrors(Map<String, dynamic> details) {
    final buffer = StringBuffer();
    details.forEach((key, value) {
      if (value is List) {
        buffer.writeln('$key: ${value.join(', ')}');
      } else {
        buffer.writeln('$key: $value');
      }
    });
    return buffer.toString().trim();
  }
}
