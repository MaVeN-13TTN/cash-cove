import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/config/routes/app_routes.dart';
import '../controllers/login_controller.dart';
import '../controllers/auth_controller.dart';
import 'widgets/index.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginController controller = Get.find<LoginController>();

  Future<void> _handleLogin(BuildContext context) async {
    // Store both scaffold context and top padding before async operation
    final scaffoldContext = ScaffoldMessenger.of(context);
    final topPadding = MediaQuery.of(context).padding.top;

    try {
      await controller.login();
      if (!mounted) return;

      final authController = Get.find<AuthController>();
      // Only show success if the login actually succeeded
      if (authController.isAuthenticated) {
        scaffoldContext.showSnackBar(
          SnackBar(
            content: const Text('Login successful!'),
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
        
        // Wait for the snackbar to be visible before navigation
        await Future.delayed(const Duration(milliseconds: 500));
        // Navigate to home_view
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      if (!mounted) return;

      // Show the actual error from the backend
      final errorMessage = controller.error.isNotEmpty 
          ? controller.error 
          : 'Invalid email or password. Please try again.';

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
  void initState() {
    super.initState();
    
    // Check for pre-filled email from signup
    final arguments = Get.arguments;
    if (arguments != null) {
      if (arguments['pre_fill_email'] != null) {
        controller.emailController.text = arguments['pre_fill_email'];
      }
      
      // Show signup success message if applicable
      if (arguments['signup_success'] == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            'Signup Successful',
            'Please log in to continue',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: LoginController.loginFormKey,
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
                      )),
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
                    onPressed: () => _handleLogin(context),
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
