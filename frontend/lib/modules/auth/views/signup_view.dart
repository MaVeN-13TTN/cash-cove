import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../controllers/signup_controller.dart';
import 'widgets/index.dart';
import '../../../app/config/routes/app_routes.dart';
import '../../../core/utils/logger_utils.dart';

class SignupView extends StatefulWidget {
  const SignupView({Key? key}) : super(key: key);

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final SignupController controller = Get.find<SignupController>();

  Future<void> _handleSignup(BuildContext context) async {
    // Store both scaffold context and top padding before async operation
    final scaffoldContext = ScaffoldMessenger.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    LoggerUtils.info('Attempting signup...');
    LoggerUtils.info('Form is valid: ${controller.isFormValid}');
    LoggerUtils.info('Terms accepted: ${controller.acceptedTerms}');
    LoggerUtils.info('Can submit: ${controller.canSubmit}');

    try {
      await controller.signup();
      if (!mounted) return;

      // Only show success if the signup actually succeeded
      if (Get.find<AuthController>().isAuthenticated) {
        scaffoldContext.showSnackBar(
          SnackBar(
            content: const Text('Registration successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            elevation: 0,
            margin: EdgeInsets.only(
              top: topPadding + 10,
              left: 10,
              right: 10,
            ),
          ),
        );
      }
    } catch (e) {
      LoggerUtils.error('Signup error', e);
      if (!mounted) return;

      // Show the actual error from the backend
      final errorMessage = controller.error.isNotEmpty
          ? controller.error
          : 'Registration failed. Please try again.';

      scaffoldContext.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          margin: EdgeInsets.only(
            top: topPadding + 10,
            left: 10,
            right: 10,
          ),
        ),
      );
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
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Start your journey to better budgeting',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // First Name Field
                AppTextField(
                  controller: controller.firstNameController,
                  label: 'First Name',
                  hint: 'Enter your first name',
                  prefixIcon: Icons.person_outline,
                  validator: controller.validateFirstName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Last Name Field
                AppTextField(
                  controller: controller.lastNameController,
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  prefixIcon: Icons.person_outline,
                  validator: controller.validateLastName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Username Field
                AppTextField(
                  controller: controller.usernameController,
                  label: 'Username',
                  hint: 'Enter your username',
                  prefixIcon: Icons.person,
                  validator: controller.validateUsername,
                ),
                const SizedBox(height: 16),

                // Email Field
                Obx(() => Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    AppTextField(
                      controller: controller.emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: controller.validateEmail,
                      errorText: controller.emailError.isNotEmpty ? controller.emailError : null,
                    ),
                    if (controller.isCheckingEmail)
                      Positioned(
                        right: 12,
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                )),
                const SizedBox(height: 16),

                // Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Obx(() => AppTextField(
                          controller: controller.passwordController,
                          label: 'Password',
                          hint: 'Create a password',
                          obscureText: controller.obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffix: IconButton(
                            icon: Icon(
                              controller.obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: controller.togglePasswordVisibility,
                          ),
                          validator: controller.validatePassword,
                          onChanged: controller.updatePasswordStrength,
                        )),
                    const SizedBox(height: 8),
                    // Password Strength Indicator
                    Obx(() => LinearProgressIndicator(
                          value: controller.passwordStrength / 4,
                          backgroundColor: Colors.grey[200],
                          color: controller.passwordStrengthColor,
                        )),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                          controller.passwordStrengthText,
                          style: TextStyle(
                            color: controller.passwordStrengthColor,
                            fontSize: 12,
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                Obx(() => AppTextField(
                      controller: controller.confirmPasswordController,
                      label: 'Confirm Password',
                      hint: 'Confirm your password',
                      obscureText: controller.obscureConfirmPassword,
                      prefixIcon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          controller.obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: controller.toggleConfirmPasswordVisibility,
                      ),
                      validator: controller.validateConfirmPassword,
                    )),
                const SizedBox(height: 16),

                // Terms and Conditions
                Obx(() => CheckboxListTile(
                      value: controller.acceptedTerms,
                      onChanged: (_) => controller.toggleTermsAcceptance(),
                      title: Row(
                        children: [
                          const Text('I accept the '),
                          GestureDetector(
                            onTap: controller.showTermsAndConditions,
                            child: Text(
                              'Terms and Conditions',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    )),
                const SizedBox(height: 24),

                // Sign Up Button
                Obx(() => AuthButton(
                      onPressed: controller.canSubmit
                          ? () => _handleSignup(context)
                          : () {},
                      text: 'Sign Up',
                      isLoading: Get.find<AuthController>().isLoading,
                    )),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.login),
                      child: const Text('Log In'),
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
