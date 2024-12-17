import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../shared/widgets/dialogs/dialog_service.dart';
import 'auth_controller.dart';
import 'package:dio/dio.dart';

class LoginController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final AuthController _authController = Get.find<AuthController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final _obscurePassword = true.obs;
  final _isLoading = false.obs;
  final _error = ''.obs;
  final _rememberMe = false.obs;
  final _remainingAttempts = 5.obs;
  final _isLocked = false.obs;
  final _lockoutEndTime = Rx<DateTime?>(null);

  bool get obscurePassword => _obscurePassword.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get rememberMe => _rememberMe.value;
  int get remainingAttempts => _remainingAttempts.value;
  bool get isLocked => _isLocked.value;
  DateTime? get lockoutEndTime => _lockoutEndTime.value;
  GlobalKey<FormState> get loginFormKey => formKey;

  @override
  void onInit() {
    super.onInit();
    _checkLockStatus();
    // Check for registration success message
    if (Get.arguments != null && Get.arguments['message'] != null) {
      _error.value = Get.arguments['message'];
      // Pre-fill email if provided
      if (Get.arguments['email'] != null) {
        emailController.text = Get.arguments['email'];
      }
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  void toggleRememberMe() {
    _rememberMe.value = !_rememberMe.value;
  }

  Future<void> login() async {
    if (!_validateForm()) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      final response = await _dioClient.post(
        '/auth/token/',
        data: {
          'email': emailController.text,
          'password': passwordController.text,
        },
      );

      // Get tokens directly from response data
      final accessToken = response.data['access'];
      final refreshToken = response.data['refresh'];

      // Store tokens
      await StorageUtils.setAccessToken(accessToken);
      await StorageUtils.setRefreshToken(refreshToken);

      // Update the authorization header in the API client
      await _dioClient.updateAuthToken(accessToken);

      // Store user data if needed
      if (response.data['user'] != null) {
        await _authController.setUserData(response.data['user']);
      }

      Get.offAllNamed(AppRoutes.home);
    } on DioException catch (e) {
      LoggerUtils.error('Login failed', e);
      if (e.response?.statusCode == 401) {
        _error.value = 'Invalid email or password';
      } else {
        _error.value = 'An error occurred during login. Please try again.';
      }
      _handleLoginError(e);
    } catch (e) {
      LoggerUtils.error('Unexpected login error', e);
      _error.value = 'An unexpected error occurred';
    } finally {
      _isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) {
      return false;
    }
    return true;
  }

  void _handleLoginError(DioException e) {
    _remainingAttempts.value--;

    if (_remainingAttempts.value <= 0) {
      _lockAccount();
    }

    if (e.response?.data is Map) {
      final data = e.response?.data as Map;
      if (data.containsKey('detail')) {
        _error.value = data['detail'];
      } else {
        _error.value = 'Invalid credentials';
      }
    } else {
      _error.value = 'Login failed. Please try again.';
    }
  }

  void _lockAccount() {
    _isLocked.value = true;
    _lockoutEndTime.value = DateTime.now().add(const Duration(minutes: 15));
    _error.value = 'Account locked. Please try again in 15 minutes.';
  }

  void _checkLockStatus() {
    if (_lockoutEndTime.value != null) {
      if (DateTime.now().isAfter(_lockoutEndTime.value!)) {
        // Lock period expired
        _isLocked.value = false;
        _lockoutEndTime.value = null;
        _remainingAttempts.value = 5;
      }
    }
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
    return null;
  }

  // Navigation Methods
  void navigateToForgotPassword() {
    Get.delete<LoginController>();
    Get.toNamed(AppRoutes.forgotPassword);
  }

  void navigateToSignup() {
    Get.delete<LoginController>();
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
      await DialogService.showError(
        context: Get.context!,
        title: 'Error',
        message: 'Failed to sign in with Google',
      );
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
      await DialogService.showError(
        context: Get.context!,
        title: 'Error',
        message: 'Failed to sign in with Facebook',
      );
    }
  }
}
