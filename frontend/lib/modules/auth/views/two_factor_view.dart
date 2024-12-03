import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../shared/widgets/buttons/primary_button.dart';
import '../../../shared/widgets/text_fields/primary_text_field.dart';

class TwoFactorView extends GetView<AuthController> {
  const TwoFactorView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final email = args?['email'] as String?;
    final token = args?['token'] as String?;

    if (email == null || token == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Invalid 2FA verification request',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      );
    }

    final verificationCodeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter Verification Code',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'A verification code has been sent to your registered email: $email',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryTextField(
              controller: verificationCodeController,
              labelText: 'Verification Code',
              hintText: 'Enter 6-digit code',
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            Obx(() => PrimaryButton(
                  onPressed: controller.isLoading 
                      ? null 
                      : () {
                          final code = verificationCodeController.text.trim();
                          if (code.length == 6) {
                            // TODO: Implement actual 2FA verification
                            Get.snackbar(
                              'Verification Attempted',
                              'Code entered: $code',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          } else {
                            Get.snackbar(
                              'Invalid Code',
                              'Please enter a 6-digit verification code',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                  text: 'Verify',
                  isLoading: controller.isLoading,
                  fullWidth: true,
                )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: controller.isLoading 
                  ? null 
                  : () {
                      Get.snackbar(
                        'Coming Soon',
                        'Resend verification code functionality is not yet implemented',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
              child: const Text('Resend Verification Code'),
            ),
          ],
        ),
      ),
    );
  }
}
