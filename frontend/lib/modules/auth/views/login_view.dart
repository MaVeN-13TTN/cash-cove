import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/login_controller.dart';
import 'widgets/index.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    icon: Icons.account_balance_wallet,
                    title: 'Welcome Back!',
                    subtitle: 'Sign in to continue tracking your budget',
                  ),
                  const SizedBox(height: 32),

                  // Account Lockout Warning
                  Obx(() {
                    if (controller.isLocked) {
                      final remaining = controller.lockoutEndTime?.difference(DateTime.now());
                      if (remaining != null && remaining.inSeconds > 0) {
                        return Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Text(
                            'Account temporarily locked. Try again in ${remaining.inMinutes} minutes.',
                            style: TextStyle(color: Colors.red.shade700),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  }),

                  // Email Field
                  Obx(() => AuthTextField(
                    controller: controller.emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: controller.validateEmail,
                    onChanged: (_) => controller.update(),
                  )),
                  const SizedBox(height: 16),

                  // Password Field
                  Obx(() => AuthTextField(
                    controller: controller.passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    obscureText: controller.obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                    validator: controller.validatePassword,
                    onChanged: (_) => controller.update(),
                  )),
                  const SizedBox(height: 8),

                  // Remaining Attempts Warning
                  Obx(() {
                    if (controller.remainingAttempts < 5 && !controller.isLocked) {
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Warning: ${controller.remainingAttempts} login attempts remaining',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  // Remember Me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => Row(
                        children: [
                          Checkbox(
                            value: controller.rememberMe,
                            onChanged: controller.isLocked ? null : (_) => controller.toggleRememberMe(),
                          ),
                          Text(
                            'Remember me',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: controller.isLocked ? Colors.grey : null,
                            ),
                          ),
                        ],
                      )),
                      TextButton(
                        onPressed: controller.isLocked ? null : controller.navigateToForgotPassword,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: controller.isLocked 
                              ? Colors.grey 
                              : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  Obx(() {
                    final isLoading = Get.find<AuthController>().isLoading;
                    return AuthButton(
                      onPressed: controller.isLocked || isLoading
                          ? () {}
                          : () { controller.login(); },
                      text: 'Login',
                      isLoading: isLoading,
                    );
                  }),
                  const SizedBox(height: 24),

                  // Social Auth Buttons
                  Obx(() => SocialAuthButtons(
                    onGoogleSignIn: controller.isLocked 
                        ? () {}
                        : () { controller.handleGoogleSignIn(); },
                    onFacebookSignIn: controller.isLocked 
                        ? () {}
                        : () { controller.handleFacebookSignIn(); },
                    onAppleSignIn: controller.isLocked 
                        ? () {}
                        : () { controller.handleAppleSignIn(); },
                  )),

                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Don\'t have an account? ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: controller.isLocked ? null : controller.navigateToSignup,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            color: controller.isLocked 
                              ? Colors.grey 
                              : Theme.of(context).primaryColor,
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
      ),
    );
  }
}