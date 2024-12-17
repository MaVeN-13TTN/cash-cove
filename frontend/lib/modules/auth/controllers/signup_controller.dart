import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/network/dio_client.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../core/utils/logger_utils.dart';
import 'package:dio/dio.dart';

class SignupController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final _obscurePassword = true.obs;
  final _obscureConfirmPassword = true.obs;
  final _acceptedTerms = false.obs;
  final _passwordStrength = 0.0.obs;
  final _isEmailAvailable = true.obs;
  final _isCheckingEmail = false.obs;
  final _isUsernameAvailable = true.obs;
  final _isCheckingUsername = false.obs;
  final _isLoading = false.obs;
  final _emailError = ''.obs;
  final _usernameError = ''.obs;
  final _passwordStrengthText = ''.obs;
  final _isFormValid = false.obs;
  final Rx<Color> _passwordStrengthColor = const Color(0xFF9E9E9E).obs;
  final RxString _error = ''.obs;

  bool get obscurePassword => _obscurePassword.value;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;
  bool get acceptedTerms => _acceptedTerms.value;
  double get passwordStrength => _passwordStrength.value;
  bool get isEmailAvailable => _isEmailAvailable.value;
  bool get isCheckingEmail => _isCheckingEmail.value;
  bool get isUsernameAvailable => _isUsernameAvailable.value;
  bool get isCheckingUsername => _isCheckingUsername.value;
  bool get isLoading => _isLoading.value;
  String get emailError => _emailError.value;
  String get usernameError => _usernameError.value;
  String get passwordStrengthText => _passwordStrengthText.value;
  Color get passwordStrengthColor => _passwordStrengthColor.value;
  bool get isFormValid => _isFormValid.value;
  String get error => _error.value;
  bool get canSubmit => isFormValid && acceptedTerms && !isLoading;

  Timer? _emailCheckTimer;
  Timer? _usernameCheckTimer;

  @override
  void onInit() {
    super.onInit();
    emailController.addListener(_onEmailChanged);
    passwordController.addListener(_onPasswordChanged);
    usernameController.addListener(_onUsernameChanged);
    firstNameController.addListener(_validateForm);
    lastNameController.addListener(_validateForm);
    confirmPasswordController.addListener(_validateForm);
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    _emailCheckTimer?.cancel();
    _usernameCheckTimer?.cancel();
    super.onClose();
  }

  void togglePasswordVisibility() {
    _obscurePassword.value = !_obscurePassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  void toggleTermsAcceptance() {
    _acceptedTerms.value = !_acceptedTerms.value;
    if (_acceptedTerms.value) {
      _validateForm();
    }
  }

  Future<void> signup() async {
    if (!_validateForm()) {
      return;
    }

    try {
      _isLoading.value = true;
      _error.value = '';

      LoggerUtils.info('Starting signup process for email: ${emailController.text}');

      // Make registration request
      final response = await _dioClient.post(
        '/auth/register/',
        data: {
          'email': emailController.text.trim(),
          'username': usernameController.text.trim(),
          'password': passwordController.text,
          'confirm_password': confirmPasswordController.text,
          'first_name': firstNameController.text.trim(),
          'last_name': lastNameController.text.trim(),
          'terms_accepted': acceptedTerms,
        },
      );

      if (response.statusCode == 201) {
        LoggerUtils.info('Registration successful for email: ${emailController.text}');
        
        // Clear form
        _clearForm();
        
        // Navigate to login page with success message
        Get.offNamed(AppRoutes.login, arguments: {
          'pre_fill_email': emailController.text.trim(),
          'signup_success': true,
        });
      }
    } on DioException catch (e) {
      LoggerUtils.error('Registration failed', e);
      _handleSignupError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  void _handleSignupError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response?.data as Map;
      final errors = <String>[];

      data.forEach((key, value) {
        if (value is List) {
          errors.add('$key: ${value.first}');
        } else if (value is String) {
          errors.add('$key: $value');
        } else {
          errors.add('$key: $value');
        }
      });

      _error.value = errors.join('\n');
      LoggerUtils.error('Signup validation errors: ${_error.value}');
    } else {
      _error.value = 'Registration failed. Please try again.';
      LoggerUtils.error('Unexpected signup error format', e.response?.data);
    }
  }

  void _clearForm() {
    firstNameController.clear();
    lastNameController.clear();
    emailController.clear();
    passwordController.clear();
    confirmPasswordController.clear();
    usernameController.clear();
    _acceptedTerms.value = false;
    _passwordStrength.value = 0.0;
    _error.value = '';
  }

  bool _validateForm() {
    if (!formKey.currentState!.validate()) {
      _isFormValid.value = false;
      LoggerUtils.info('Form validation failed');
      return false;
    }

    if (!acceptedTerms) {
      _error.value = 'Please accept the terms and conditions';
      _isFormValid.value = false;
      LoggerUtils.info('Terms not accepted');
      return false;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _error.value = 'Passwords do not match';
      _isFormValid.value = false;
      LoggerUtils.info('Passwords do not match');
      return false;
    }

    if (!_isEmailAvailable.value) {
      _error.value = 'Email is not available';
      _isFormValid.value = false;
      LoggerUtils.info('Email is not available');
      return false;
    }

    if (!_isUsernameAvailable.value) {
      _error.value = 'Username is not available';
      _isFormValid.value = false;
      LoggerUtils.info('Username is not available');
      return false;
    }

    // Check if all fields have values
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      _isFormValid.value = false;
      LoggerUtils.info('Some fields are empty');
      return false;
    }

    LoggerUtils.info('Form validation passed');
    _isFormValid.value = true;
    return true;
  }

  void _onEmailChanged() {
    _emailCheckTimer?.cancel();
    if (emailController.text.isNotEmpty) {
      _emailCheckTimer = Timer(const Duration(milliseconds: 500), () {
        _checkEmailAvailability();
        _validateForm();
      });
    }
  }

  Future<void> _checkEmailAvailability() async {
    if (!GetUtils.isEmail(emailController.text)) {
      _emailError.value = 'Please enter a valid email';
      _isEmailAvailable.value = false;
      return;
    }

    try {
      _isCheckingEmail.value = true;
      final response = await _dioClient.post(
        '/auth/check-email/',
        data: {'email': emailController.text},
      );
      _isEmailAvailable.value = response.data['available'] ?? false;
      _emailError.value = _isEmailAvailable.value ? '' : 'Email already exists';
    } catch (e) {
      LoggerUtils.error('Error checking email availability', e);
      _emailError.value = 'Error checking email availability';
    } finally {
      _isCheckingEmail.value = false;
    }
  }

  void _onUsernameChanged() {
    _usernameCheckTimer?.cancel();
    if (usernameController.text.isNotEmpty) {
      _usernameCheckTimer = Timer(const Duration(milliseconds: 500), () {
        _checkUsernameAvailability();
        _validateForm();
      });
    }
  }

  Future<void> _checkUsernameAvailability() async {
    if (usernameController.text.isEmpty) {
      _isUsernameAvailable.value = false;
      _usernameError.value = 'Username is required';
      return;
    }

    try {
      _isCheckingUsername.value = true;
      final response = await _dioClient.post(
        '/auth/check-username/',
        data: {'username': usernameController.text},
      );
      _isUsernameAvailable.value = response.data['available'] ?? false;
      _usernameError.value = _isUsernameAvailable.value ? '' : 'Username already exists';
    } catch (e) {
      LoggerUtils.error('Error checking username availability', e);
      _usernameError.value = 'Error checking username availability';
    } finally {
      _isCheckingUsername.value = false;
    }
  }

  void _onPasswordChanged() {
    final password = passwordController.text;
    updatePasswordStrength(password);
    _validateForm();
  }

  void updatePasswordStrength(String password) {
    if (password.isEmpty) {
      _passwordStrength.value = 0.0;
      _passwordStrengthText.value = '';
      _passwordStrengthColor.value = const Color(0xFF9E9E9E);
      return;
    }

    double strength = 0.0;
    String text = '';
    Color color = const Color(0xFF9E9E9E);

    if (password.length >= 8) strength += 0.2;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    if (strength <= 0.2) {
      text = 'Weak';
      color = Colors.red;
    } else if (strength <= 0.4) {
      text = 'Fair';
      color = Colors.orange;
    } else if (strength <= 0.6) {
      text = 'Good';
      color = Colors.yellow;
    } else if (strength <= 0.8) {
      text = 'Strong';
      color = Colors.lightGreen;
    } else {
      text = 'Very Strong';
      color = Colors.green;
    }

    _passwordStrength.value = strength;
    _passwordStrengthText.value = text;
    _passwordStrengthColor.value = color;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    if (!_isEmailAvailable.value) {
      return 'Email already exists';
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
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
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

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    return null;
  }

  String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (!_isUsernameAvailable.value) {
      return 'Username already exists';
    }
    return null;
  }

  String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    if (value.length < 2) {
      return 'First name must be at least 2 characters';
    }
    return null;
  }

  String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    if (value.length < 2) {
      return 'Last name must be at least 2 characters';
    }
    return null;
  }

  void navigateToLogin([String? email]) {
    Get.delete<SignupController>();
    if (email != null) {
      Get.toNamed(AppRoutes.login, arguments: {'pre_fill_email': email, 'signup_success': true});
    } else {
      Get.toNamed(AppRoutes.login);
    }
  }

  Future<void> showTermsAndConditions() async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Terms and Conditions'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                '1. You must be at least 18 years old to use this service.\n'
                '2. You are responsible for maintaining the security of your account.\n'
                '3. You agree to provide accurate and complete information.\n'
                '4. We reserve the right to suspend or terminate your account.\n'
                '5. You agree to use the service in compliance with all applicable laws.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              toggleTermsAcceptance();
              Get.back();
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }
}
