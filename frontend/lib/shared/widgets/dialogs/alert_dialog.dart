import 'package:flutter/material.dart';
import 'package:budget_tracker/shared/theme/app_colors.dart';

Future<bool?> showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmText,
  String? cancelText,
  bool isDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        if (cancelText != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText ?? 'OK'),
        ),
      ],
    ),
  );
}

Future<void> showErrorDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? buttonText,
}) {
  final theme = Theme.of(context);
  
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText ?? 'OK'),
        ),
      ],
    ),
  );
}

Future<void> showSuccessDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? buttonText,
}) {
  final theme = Theme.of(context);
  
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.extension<AppColors>()?.success ?? Colors.green,
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText ?? 'OK'),
        ),
      ],
    ),
  );
}
