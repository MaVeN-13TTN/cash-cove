import 'package:dio/dio.dart';
import '../../auth/auth_service.dart';
import '../../../services/dialog/dialog_service.dart';

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
    _dialogService.showGetDialog(
      'Authentication Error', 
      'Please log in again.'
    );
    _authService.logout();
  }

  void _handleValidationError(DioException err, dynamic details) {
    _dialogService.showGetDialog(
      'Validation Error', 
      details?.toString() ?? 'Invalid input.'
    );
  }

  void _handleNotFoundError(DioException err) {
    _dialogService.showGetDialog(
      'Not Found', 
      'The requested resource could not be found.'
    );
  }

  void _handlePermissionError(DioException err) {
    _dialogService.showGetDialog(
      'Permission Denied', 
      'You do not have permission to perform this action.'
    );
  }

  void _handleServerError(DioException err) {
    _dialogService.showGetDialog(
      'Server Error', 
      'An unexpected server error occurred.'
    );
  }

  void _handleUnknownError(DioException err) {
    _dialogService.showGetDialog(
      'Error', 
      'An unexpected error occurred.'
    );
  }
}
