import 'package:flutter/material.dart';
import '../../../../core/widgets/app_button.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;

  const AuthButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      variant: isOutlined ? AppButtonVariant.outline : AppButtonVariant.primary,
      size: AppButtonSize.large,
      fullWidth: true,
    );
  }
}
