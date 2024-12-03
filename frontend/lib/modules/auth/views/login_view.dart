import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AuthHeader(
                    icon: Icons.account_balance_wallet,
                    title: 'Welcome Back!',
                    subtitle: 'Sign in to continue tracking your budget',
                  ),
                  const SizedBox(height: 40),

                  // Error Message
                  GetX<LoginController>(
                    builder: (controller) {
                      return Column(
                        children: [
                          if (controller.isLocked)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Account is locked. Try again later.',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (controller.remainingAttempts < 5)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(
                                'Attempts remaining: ${controller.remainingAttempts}',
                                style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  AuthTextField(
                    controller: controller.emailController,
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: controller.validateEmail,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  AuthTextField(
                    controller: controller.passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    obscureText: controller.obscurePassword,
                    prefixIcon: Icons.lock_outline,
                    validator: controller.validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        controller.obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: controller.togglePasswordVisibility,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Remember Me and Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() => Row(
                            children: [
                              Checkbox(
                                value: controller.rememberMe,
                                onChanged: (value) =>
                                    controller.toggleRememberMe(),
                              ),
                              const Text('Remember Me'),
                            ],
                          )),
                      TextButton(
                        onPressed: () => controller.navigateToForgotPassword(),
                        child: const Text('Forgot Password?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Login Button
                  AuthButton(
                    onPressed: () => controller.login(),
                    text: 'Login',
                  ),
                  const SizedBox(height: 30),

                  // Social Auth Buttons
                  SocialAuthButtons(
                    onGoogleSignIn: () {
                      // Handle Google Sign-In
                      controller.handleGoogleSignIn();
                    },
                    onFacebookSignIn: () {
                      // Handle Facebook Sign-In
                      controller.handleFacebookSignIn();
                    },
                  ),
                  const SizedBox(height: 30),

                  // Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account yet? "),
                      TextButton(
                        onPressed: () => controller.navigateToSignup(),
                        child: const Text('Sign Up'),
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
