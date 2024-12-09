import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../core/network/dio_client.dart';
import 'auth_controller.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../core/services/error/error_service.dart';
import '../../../core/utils/storage_utils.dart';
import '../../../shared/widgets/dialogs/dialog_service.dart';
import '../../../core/utils/logger_utils.dart';

class SignupController extends GetxController {
  final DioClient _dioClient = Get.find<DioClient>();
  final ErrorService _errorService = Get.find<ErrorService>();
  final AuthController _authController = Get.find<AuthController>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final usernameController = TextEditingController();
  static final formKey = GlobalKey<FormState>();

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
  final RxString _error = ''.obs;

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
  String get error => _error.value;

  Timer? _emailCheckTimer;

  @override
  void onInit() {
    super.onInit();
    _setupControllers();
  }

  @override
  void onClose() {
    _emailCheckTimer?.cancel();
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    usernameController.dispose();
    Get.delete<SignupController>();
    super.onClose();
  }

  void _setupControllers() {
    emailController.addListener(_validateForm);
    passwordController.addListener(_onPasswordChanged);
    confirmPasswordController.addListener(_validateForm);
  }

  void togglePasswordVisibility() => _obscurePassword.toggle();
  void toggleConfirmPasswordVisibility() => _obscureConfirmPassword.toggle();
  void toggleTerms(bool? value) => _acceptedTerms.value = value ?? false;

  void _onPasswordChanged() {
    if (passwordController.text.isEmpty) {
      _passwordStrength.value = 0;
      _passwordStrengthText.value = '';
      _passwordStrengthColor.value = const Color(0xFF9E9E9E);
      return;
    }

    final password = passwordController.text;
    double strength = 0;
    String text = '';
    Color color = Colors.red;

    if (password.length >= 8) strength += 0.5;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.5;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.5;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.5;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 1;

    if (strength <= 1) {
      text = 'Weak';
      color = Colors.red;
    } else if (strength <= 2) {
      text = 'Medium';
      color = Colors.orange;
    } else {
      text = 'Strong';
      color = Colors.green;
    }

    _passwordStrength.value = strength;
    _passwordStrengthText.value = text;
    _passwordStrengthColor.value = color;
    _validateForm();
  }

  // Form Validation Methods
  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
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
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, and underscores';
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
    if (!_isEmailAvailable.value) {
      return 'This email is already in use';
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

  void updatePasswordStrength(String value) {
    _onPasswordChanged();
  }

  void toggleTermsAcceptance() {
    _acceptedTerms.toggle();
    _validateForm();
  }

  void showTermsAndConditions() {
    Get.dialog(
      AlertDialog(
        title: const Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text(
            'By accepting these terms, you agree to our Privacy Policy and Terms of Service...',
            style: Get.textTheme.bodyMedium,
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

  bool get canSubmit {
    return isFormValid && 
           acceptedTerms && 
           !isLoading && 
           !isCheckingEmail && 
           passwordStrength >= 2.0;
  }

  void _validateForm() {
    _isFormValid.value = SignupController.formKey.currentState?.validate() ?? false;
  }

  Future<void> signup() async {
    _validateForm();
    if (!_isFormValid.value) return;

    // Trigger email check before proceeding
    await _checkEmailAvailability();

    if (!_isEmailAvailable.value) {
      _error.value = 'Email is not available';
      return;
    }

    _isLoading.value = true;
    _error.value = '';

    try {
      final response = await _dioClient.post('/auth/register/', data: {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'confirm_password': confirmPasswordController.text,
        'username': usernameController.text.trim(),
        'terms_accepted': _acceptedTerms.value,
      });

      if (response.statusCode == 201) {
        await _handleSuccessfulSignup(response.data);
      } else {
        throw 'Invalid response from server';
      }
    } catch (e) {
      LoggerUtils.error('Signup error', e);
      _errorService.handleError(e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _checkEmailAvailability() async {
    if (emailController.text.isEmpty || !GetUtils.isEmail(emailController.text)) {
      _emailError.value = 'Invalid email format';
      _isEmailAvailable.value = false;
      return;
    }

    try {
      _isCheckingEmail.value = true;
      _emailError.value = '';

      final response = await _dioClient.get('/auth/check-email/',
          queryParameters: {'email': emailController.text.trim()});

      _isEmailAvailable.value = response.data['is_available'];
    } catch (e) {
      LoggerUtils.error('Email check error', e);
      _isEmailAvailable.value = false;
    } finally {
      _isCheckingEmail.value = false;
    }
  }

  Future<void> _handleSuccessfulSignup(Map<String, dynamic> data) async {
    // Handle successful signup logic
    LoggerUtils.info('Starting signup process for: ${emailController.text}');

    await DialogService.showLoading(
      context: Get.context!,
      title: 'Creating Account',
      message: 'Please wait while we set up your account...',
    );

    if (data['requires_verification'] == true) {
      // Store email for login view
      await StorageUtils.setTemporaryEmail(emailController.text);
      
      // Update auth state to reflect new registration
      await _authController.updateRegistrationState(
        email: emailController.text,
        requiresVerification: data['requires_verification'] ?? false,
      );

      await DialogService.showSuccess(
        context: Get.context!,
        title: 'Success',
        message: 'Account created! Please check your email to verify your account.',
      );

      // Navigate based on verification requirement
      Get.offNamed(AppRoutes.verifyEmail);
    } else {
      // Store email for login view
      await StorageUtils.setTemporaryEmail(emailController.text);
      
      // Update auth state to reflect new registration
      await _authController.updateRegistrationState(
        email: emailController.text,
        requiresVerification: data['requires_verification'] ?? false,
      );

      await DialogService.showSuccess(
        context: Get.context!,
        title: 'Success',
        message: 'Account created successfully! Please log in.',
      );

      // Navigate based on verification requirement
      Get.offNamed(AppRoutes.login);
    }
  }
}
