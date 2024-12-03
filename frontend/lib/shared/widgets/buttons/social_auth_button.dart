import 'package:flutter/material.dart';

enum SocialAuthProvider { google, facebook, apple }

class SocialAuthButton extends StatelessWidget {
  final SocialAuthProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialAuthButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String text;
    IconData icon;
    switch (provider) {
      case SocialAuthProvider.google:
        text = 'Google';
        icon = Icons.g_mobiledata;
        break;
      case SocialAuthProvider.facebook:
        text = 'Facebook';
        icon = Icons.facebook;
        break;
      case SocialAuthProvider.apple:
        text = 'Continue with Apple';
        icon = Icons.apple;
        break;
    }

    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: BorderSide(color: theme.dividerColor),
        backgroundColor: theme.colorScheme.surface,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 24),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
    );
  }
}