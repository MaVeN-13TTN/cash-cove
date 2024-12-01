import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'widgets/index.dart';

class ForgotPasswordView extends StatelessWidget {
  ForgotPasswordView({Key? key}) : super(key: key);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authController = Get.find<AuthController>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    try {
      await _authController.forgotPassword(_emailController.text.trim());
      Get.snackbar(
        'Success',
        'Password reset instructions have been sent to your email',
        backgroundColor: Colors.green[50],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 5),
      );
      await Future.delayed(const Duration(seconds: 2));
      Get.back(); // Return to login page after showing success message
    } catch (e) {
      // Error is already handled in AuthController
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthHeader(
                  icon: Icons.lock_reset,
                  title: 'Forgot Password?',
                  subtitle: 'Enter your email address and we\'ll send you instructions to reset your password.',
                ),
                const SizedBox(height: 32),

                // Email Field
                AuthTextField(
                  controller: _emailController,
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: _validateEmail,
                  onSubmitted: (_) => _resetPassword(),
                ),
                const SizedBox(height: 24),

                // Reset Password Button
                Obx(() => AuthButton(
                  onPressed: _resetPassword,
                  text: 'Reset Password',
                  isLoading: _authController.isLoading,
                )),
                const SizedBox(height: 24),

                // Security Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Tips:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Check your spam folder if you don\'t see the email\n'
                        '• Reset link expires in 30 minutes\n'
                        '• Make sure to use a strong password',
                        style: TextStyle(
                          color: Colors.blue[900],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}