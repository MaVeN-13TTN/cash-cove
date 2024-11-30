import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, text }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    Widget buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  variant == AppButtonVariant.primary
                      ? colors.surface
                      : colors.primary,
                ),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Icon(
              icon,
              size: 20,
            ),
          ),
        Text(
          text,
          style: theme.textTheme.labelLarge,
        ),
      ],
    );

    EdgeInsetsGeometry padding;
    switch (size) {
      case AppButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        break;
      case AppButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
        break;
      case AppButtonSize.medium:
      default:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
    }

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: padding,
            backgroundColor: colors.primary,
            foregroundColor: colors.surface,
            disabledBackgroundColor: colors.primary.withOpacity(0.6),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            padding: padding,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.primary,
            disabledBackgroundColor: colors.primaryContainer.withOpacity(0.6),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.outline:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding,
            foregroundColor: colors.primary,
            side: BorderSide(color: colors.primary),
          ),
          child: buttonChild,
        );
        break;
      case AppButtonVariant.text:
        button = TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            padding: padding,
            foregroundColor: colors.primary,
          ),
          child: buttonChild,
        );
        break;
    }

    if (fullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}
