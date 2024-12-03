import 'package:flutter/material.dart';
import '../../../../shared/widgets/buttons/social_auth_button.dart';

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGoogleSignIn;
  final VoidCallback onFacebookSignIn;

  const SocialAuthButtons({
    Key? key,
    required this.onGoogleSignIn,
    required this.onFacebookSignIn,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SocialAuthButton(
                  provider: SocialAuthProvider.google,
                  onPressed: onGoogleSignIn,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SocialAuthButton(
                  provider: SocialAuthProvider.facebook,
                  onPressed: onFacebookSignIn,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
