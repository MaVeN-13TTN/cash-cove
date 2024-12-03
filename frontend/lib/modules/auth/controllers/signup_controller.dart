import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/services/api/api_client.dart';
import 'auth_controller.dart';

class SignupController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final ApiClient _apiClient = Get.find<ApiClient>();
  
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final _obscurePassword = true.obs;
  final _obscureConfirmPassword = true.obs;
  final _acceptedTerms = false.obs;
  final _passwordStrength = 0.0.obs;
  final _isEmailAvailable = true.obs;
  final _isCheckingEmail = false.obs;
  final _isLoading = false.obs;
  final _emailError = ''.obs;
  final _passwordStrengthText = ''.obs;
  final _isFormValid = false.obs;
  final Rx<Color> _passwordStrengthColor = const Color(0xFF9E9E9E).obs;

  bool get obscurePassword => _obscurePassword.value;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;
  bool get acceptedTerms => _acceptedTerms.value;
  double get passwordStrength => _passwordStrength.value;
  bool get isEmailAvailable => _isEmailAvailable.value;
  bool get isCheckingEmail => _isCheckingEmail.value;
  bool get isLoading => _isLoading.value;
  String get emailError => _emailError.value;
  String get passwordStrengthText => _passwordStrengthText.value;
  Color get passwordStrengthColor => _passwordStrengthColor.value;
  bool get isFormValid => _isFormValid.value;

  bool get canSubmit {
    return isFormValid && 
           acceptedTerms && 
           !isLoading &&
           !isCheckingEmail &&
           passwordStrength >= 2.0;
  }

  void validateForm() {
    _isFormValid.value = formKey.currentState?.validate() ?? false;
  }

  void togglePasswordVisibility() => _obscurePassword.toggle();
  void toggleConfirmPasswordVisibility() => _obscureConfirmPassword.toggle();
  void toggleTermsAcceptance() => _acceptedTerms.toggle();

  void updatePasswordStrength(String password) {
    double strength = 0;
    
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    _passwordStrength.value = strength;

    switch (strength) {
      case 0:
        _passwordStrengthText.value = 'Very Weak';
        _passwordStrengthColor.value = const Color(0xFFD32F2F);
        break;
      case 1:
        _passwordStrengthText.value = 'Weak';
        _passwordStrengthColor.value = const Color(0xFFF57C00);
        break;
      case 2:
        _passwordStrengthText.value = 'Medium';
        _passwordStrengthColor.value = const Color(0xFFFFA000);
        break;
      case 3:
        _passwordStrengthText.value = 'Strong';
        _passwordStrengthColor.value = const Color(0xFF388E3C);
        break;
      case 4:
        _passwordStrengthText.value = 'Very Strong';
        _passwordStrengthColor.value = const Color(0xFF2E7D32);
        break;
    }
  }

  Future<bool> checkEmailAvailability(String email) async {
    try {
      _isCheckingEmail.value = true;
      _emailError.value = '';
      
      final response = await _apiClient.get('/auth/check-email/', queryParameters: {
        'email': email,
      });

      final available = response.data['available'] ?? false;
      _isEmailAvailable.value = !available;
      
      if (available) {
        _emailError.value = 'Email is already in use';
        return false;
      }
      return true;
    } catch (e) {
      _emailError.value = 'Error checking email availability';
      _isEmailAvailable.value = false;
      return false;
    } finally {
      _isCheckingEmail.value = false;
    }
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
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
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void showTermsAndConditions() {
    Get.dialog(
      AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const SingleChildScrollView(
          child: Text(
            'By creating an account, you agree to our Terms of Service and Privacy Policy. '
            'We are committed to protecting your personal information and ensuring a secure experience. '
            'You must be at least 13 years old to use this service. '
            'You agree to provide accurate information and maintain the security of your account.'
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> signup() async {
    if (!canSubmit) return;

    try {
      await _authController.signup(
        nameController.text.trim(),
        emailController.text.trim(),
        passwordController.text,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        _authController.error,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Add listeners to validate form when text changes
    nameController.addListener(validateForm);
    emailController.addListener(validateForm);
    passwordController.addListener(() {
      updatePasswordStrength(passwordController.text);
      validateForm();
    });
    confirmPasswordController.addListener(validateForm);
  }

  @override
  void onClose() {
    nameController.removeListener(validateForm);
    emailController.removeListener(validateForm);
    passwordController.removeListener(() {
      updatePasswordStrength(passwordController.text);
      validateForm();
    });
    confirmPasswordController.removeListener(validateForm);
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}