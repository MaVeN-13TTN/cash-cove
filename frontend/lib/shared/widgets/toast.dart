import 'package:flutter/material.dart';
import 'package:budget_tracker/shared/theme/app_colors.dart';

enum ToastVariant {
  success,
  error,
  warning,
  info,
}

class Toast extends StatelessWidget {
  final String message;
  final ToastVariant variant;
  final VoidCallback? onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  const Toast({
    super.key,
    required this.message,
    this.variant = ToastVariant.info,
    this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color iconColor;
    IconData icon;

    switch (variant) {
      case ToastVariant.success:
        backgroundColor = theme.extension<AppColors>()?.success ?? Colors.green;
        iconColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case ToastVariant.error:
        backgroundColor = theme.colorScheme.error;
        iconColor = theme.colorScheme.onError;
        icon = Icons.error;
        break;
      case ToastVariant.warning:
        backgroundColor = theme.extension<AppColors>()?.warning ?? Colors.orange;
        iconColor = Colors.white;
        icon = Icons.warning;
        break;
      case ToastVariant.info:
        backgroundColor = theme.extension<AppColors>()?.info ?? Colors.blue;
        iconColor = Colors.white;
        icon = Icons.info;
        break;
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: onDismiss != null ? 4 : 16,
                  top: 12,
                  bottom: actionLabel != null ? 8 : 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: iconColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (onDismiss != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: iconColor,
                        onPressed: onDismiss,
                      ),
                  ],
                ),
              ),
              if (actionLabel != null)
                Padding(
                  padding: const EdgeInsets.only(
                    right: 8,
                    bottom: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: onAction,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(actionLabel!),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showToast(
  BuildContext context, {
  required String message,
  ToastVariant variant = ToastVariant.info,
  Duration duration = const Duration(seconds: 4),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Toast(
        message: message,
        variant: variant,
        onDismiss: () => overlayEntry.remove(),
        actionLabel: actionLabel,
        onAction: onAction != null
            ? () {
                onAction();
                overlayEntry.remove();
              }
            : null,
      ),
    ),
  );

  overlay.insert(overlayEntry);

  if (onAction == null) {
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
