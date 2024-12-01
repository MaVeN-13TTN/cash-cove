import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/storage_utils.dart';
import 'auth_controller.dart';

class LoginController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _obscurePassword = true.obs;
  final _rememberMe = false.obs;
  final _isLocked = false.obs;
  final _lockoutEndTime = Rxn<DateTime>();
  final _remainingAttempts = 5.obs;

  bool get obscurePassword => _obscurePassword.value;
  bool get rememberMe => _rememberMe.value;
  bool get isLocked => _isLocked.value;
  DateTime? get lockoutEndTime => _lockoutEndTime.value;
  int get remainingAttempts => _remainingAttempts.value;

  void togglePasswordVisibility() => _obscurePassword.toggle();
  void toggleRememberMe() => _rememberMe.toggle();

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

  Future<void> login() async {
    if (isLocked) {
      final remaining = lockoutEndTime?.difference(DateTime.now());
      if (remaining != null && remaining.inSeconds > 0) {
        Get.snackbar(
          'Account Locked',
          'Please try again in ${remaining.inMinutes} minutes',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      } else {
        _isLocked.value = false;
        _remainingAttempts.value = 5;
      }
    }

    if (!formKey.currentState!.validate()) return;

    try {
      await _authController.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (rememberMe) {
        // Save email for next time
        await StorageUtils.saveSecure('last_email', emailController.text.trim());
      }

      _remainingAttempts.value = 5;
      _isLocked.value = false;
    } catch (e) {
      if (e.toString().contains('423')) { // Account locked
        _isLocked.value = true;
        _lockoutEndTime.value = DateTime.now().add(const Duration(minutes: 30));
        Get.snackbar(
          'Account Locked',
          'Too many failed attempts. Please try again in 30 minutes',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else if (e.toString().contains('429')) { // Rate limited
        _remainingAttempts.value--;
        if (_remainingAttempts.value <= 0) {
          _isLocked.value = true;
          _lockoutEndTime.value = DateTime.now().add(const Duration(minutes: 5));
        }
        Get.snackbar(
          'Warning',
          'Too many attempts. ${_remainingAttempts.value} attempts remaining',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }
  }

  void handleGoogleSignIn() {
    try {
      Get.find<AuthController>().signInWithGoogle();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign in with Google: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void handleFacebookSignIn() {
    try {
      Get.find<AuthController>().signInWithFacebook();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign in with Facebook: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void handleAppleSignIn() {
    try {
      Get.find<AuthController>().signInWithApple();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to sign in with Apple: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void navigateToSignup() {
    Get.toNamed('/signup');
  }

  void navigateToForgotPassword() {
    Get.toNamed('/forgot-password');
  }

  @override
  void onInit() {
    super.onInit();
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await StorageUtils.getSecure('last_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      emailController.text = savedEmail;
      _rememberMe.value = true;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}