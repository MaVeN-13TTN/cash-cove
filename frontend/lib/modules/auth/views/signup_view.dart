import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../controllers/signup_controller.dart';
import 'widgets/index.dart';

class SignupView extends GetView<SignupController> {
  const SignupView({Key? key}) : super(key: key);

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

                // Name Field
                AppTextField(
                  controller: controller.nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  validator: controller.validateName,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Email Field
                AppTextField(
                  controller: controller.emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: controller.validateEmail,
                  onChanged: controller.checkEmailAvailability,
                ),
                const SizedBox(height: 16),

                // Email Availability Status
                Obx(() {
                  if (controller.isCheckingEmail) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Checking email availability...'),
                        ],
                      ),
                    );
                  } else if (controller.emailError.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        controller.emailError,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

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
                    ? () { controller.signup(); }
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
                      onPressed: () => Get.back(),
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