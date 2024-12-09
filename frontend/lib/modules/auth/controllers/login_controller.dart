import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' show DioException;
import '../../../core/network/dio_client.dart';
import '../../../core/utils/storage_utils.dart';
import 'auth_controller.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../shared/widgets/dialogs/dialog_service.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/services/error/error_service.dart';

class LoginController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final ErrorService _errorService = Get.find<ErrorService>();
  final AuthController _authController = Get.find<AuthController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  static final loginFormKey = GlobalKey<FormState>();

  final _obscurePassword = true.obs;
  final _rememberMe = false.obs;
  final _isLocked = false.obs;
  final _lockoutEndTime = Rxn<DateTime>();
  final _remainingAttempts = 5.obs;
  final _isLoading = false.obs;
  final RxString _error = ''.obs;

  bool get obscurePassword => _obscurePassword.value;
  bool get rememberMe => _rememberMe.value;
  bool get isLocked => _isLocked.value;
  DateTime? get lockoutEndTime => _lockoutEndTime.value;
  int get remainingAttempts => _remainingAttempts.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    _loadSavedEmail();
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    Get.delete<LoginController>();
    super.onClose();
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await StorageUtils.getTemporaryEmail();
    if (savedEmail != null) {
      emailController.text = savedEmail;
      await StorageUtils.clearTemporaryEmail();
    }
  }

  void togglePasswordVisibility() => _obscurePassword.toggle();
  void toggleRememberMe() => _rememberMe.toggle();

  Future<void> login() async {
    if (!_validateForm()) return;
    if (_isLocked.value) {
      _errorService.handleError('Account is temporarily locked. Please try again later.');
      return;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      LoggerUtils.info('Attempting login for user: ${emailController.text}');

      await DialogService.showLoading(
        context: Get.context!,
        title: 'Logging in',
        message: 'Please wait...',
      );

      final response = await _dioClient.post('/auth/token/', data: {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });

      if (response.statusCode == 200 && response.data != null) {
        await _handleSuccessfulLogin(response.data);
      } else {
        throw 'Invalid response from server';
      }
    } catch (e) {
      LoggerUtils.error('Login error', e);
      DialogService.hideLoading(Get.context!);
      _handleLoginError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> data) async {
    try {
      LoggerUtils.info('Login successful, storing user data');
      
      // Store tokens
      await StorageUtils.setAccessToken(data['access']);
      await StorageUtils.setRefreshToken(data['refresh']);

      // Store user data if available
      if (data['user'] != null) {
        await StorageUtils.setUserData(data['user']);
      }

      // Reset login attempts
      _remainingAttempts.value = 5;
      _isLocked.value = false;
      _lockoutEndTime.value = null;

      DialogService.hideLoading(Get.context!);

      // Update auth state
      await _authController.checkAuthStatus();

      // Show success message
      await DialogService.showSuccess(
        context: Get.context!,
        title: 'Success',
        message: 'Logged in successfully!',
      );

      // Navigate to home after brief delay
      await Future.delayed(const Duration(milliseconds: 500));
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      LoggerUtils.error('Error saving login data', e);
      _errorService.handleError('Error saving login data');
      rethrow;
    }
  }

  void _handleLoginError(dynamic error) {
    _remainingAttempts.value--;
    LoggerUtils.warning('Failed login attempt. Remaining attempts: ${_remainingAttempts.value}');

    if (_remainingAttempts.value <= 0) {
      _isLocked.value = true;
      _lockoutEndTime.value = DateTime.now().add(const Duration(minutes: 15));
      _error.value = 'Too many failed attempts. Account locked for 15 minutes.';
      LoggerUtils.warning('Account locked due to too many failed attempts');
    } else {
      if (error is DioException) {
        switch (error.response?.statusCode) {
          case 401:
            _error.value = 'Invalid email or password';
            break;
          case 403:
            _error.value = 'Account is locked. Please reset your password.';
            break;
          case 429:
            _error.value = 'Too many attempts. Please try again later.';
            break;
          default:
            _error.value = 'Login failed. Please try again.';
        }
      } else {
        _error.value = 'An error occurred. Please try again.';
      }
    }

    _errorService.handleError(_error.value);
  }

  bool _validateForm() {
    if (!loginFormKey.currentState!.validate()) {
      _errorService.handleError('Please fill in all required fields correctly.');
      return false;
    }
    return true;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // Navigation Methods
  void navigateToForgotPassword() {
    LoggerUtils.info('Navigating to forgot password screen');
    Get.toNamed(AppRoutes.forgotPassword);
  }

  void navigateToSignup() {
    LoggerUtils.info('Navigating to register screen');
    Get.toNamed(AppRoutes.register);
  }

  // Social Sign In Methods
  Future<void> handleGoogleSignIn() async {
    try {
      LoggerUtils.info('Initiating Google Sign In');
      await DialogService.showLoading(
        context: Get.context!,
        title: 'Google Sign In',
        message: 'Please wait...',
      );
      
      await _authController.signInWithGoogle();
      
      DialogService.hideLoading(Get.context!);
      await DialogService.showSuccess(
        context: Get.context!,
        title: 'Success',
        message: 'Successfully signed in with Google',
      );
      
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      DialogService.hideLoading(Get.context!);
      LoggerUtils.error('Google Sign In error', e);
      _errorService.handleError(e);
    }
  }

  Future<void> handleFacebookSignIn() async {
    try {
      LoggerUtils.info('Initiating Facebook Sign In');
      await DialogService.showLoading(
        context: Get.context!,
        title: 'Facebook Sign In',
        message: 'Please wait...',
      );
      
      await _authController.signInWithFacebook();
      
      DialogService.hideLoading(Get.context!);
      await DialogService.showSuccess(
        context: Get.context!,
        title: 'Success',
        message: 'Successfully signed in with Facebook',
      );
      
      Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      DialogService.hideLoading(Get.context!);
      LoggerUtils.error('Facebook Sign In error', e);
      _errorService.handleError(e);
    }
  }
}
