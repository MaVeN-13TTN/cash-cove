import 'package:flutter/material.dart';
import '../../../../shared/widgets/buttons/social_auth_button.dart';

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onFacebookSignIn;
  final VoidCallback onAppleSignIn;

  const SocialAuthButtons({
    Key? key,
    required this.onGoogleSignIn,
    required this.onFacebookSignIn,
    required this.onAppleSignIn,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SocialAuthButton(
              provider: SocialAuthProvider.google,
              onPressed: onGoogleSignIn,
            ),
            SocialAuthButton(
              provider: SocialAuthProvider.facebook,
              onPressed: onFacebookSignIn,
            ),
            SocialAuthButton(
              provider: SocialAuthProvider.apple,
              onPressed: onAppleSignIn,
            ),
          ],
        ),
      ],
    );
  }
}
