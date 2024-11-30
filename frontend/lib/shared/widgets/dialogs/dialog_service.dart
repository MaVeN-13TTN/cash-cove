import 'package:flutter/material.dart';
import 'package:budget_tracker/shared/theme/app_colors.dart';

enum DialogType {
  alert,
  confirm,
  success,
  error,
  warning,
  loading,
}

class DialogConfig {
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final bool isDismissible;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? customContent;

  const DialogConfig({
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.isDismissible = true,
    this.onConfirm,
    this.onCancel,
    this.customContent,
  });
}

class DialogService {
  static Future<T?> showCustomDialog<T>({
    required BuildContext context,
    required DialogType type,
    required DialogConfig config,
  }) {
    final theme = Theme.of(context);

    IconData getIcon() {
      switch (type) {
        case DialogType.success:
          return Icons.check_circle_outline;
        case DialogType.error:
          return Icons.error_outline;
        case DialogType.warning:
          return Icons.warning_amber_rounded;
        case DialogType.confirm:
          return Icons.help_outline_rounded;
        default:
          return Icons.info_outline;
      }
    }

    Color getIconColor() {
      switch (type) {
        case DialogType.success:
          return theme.extension<AppColors>()?.success ?? Colors.green;
        case DialogType.error:
          return theme.colorScheme.error;
        case DialogType.warning:
          return theme.extension<AppColors>()?.warning ?? Colors.orange;
        default:
          return theme.colorScheme.primary;
      }
    }

    Widget buildTitle() {
      if (type == DialogType.loading) {
        return Text(config.title);
      }

      return Row(
        children: [
          Icon(
            getIcon(),
            color: getIconColor(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              config.title,
              style: TextStyle(
                color: type == DialogType.error ? theme.colorScheme.error : null,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildContent() {
      if (config.customContent != null) {
        return config.customContent!;
      }

      if (type == DialogType.loading) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (config.message.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(config.message),
            ],
          ],
        );
      }

      return Text(config.message);
    }

    List<Widget> buildActions() {
      if (type == DialogType.loading) {
        return [];
      }

      return [
        if (config.cancelText != null || type == DialogType.confirm)
          TextButton(
            onPressed: () {
              config.onCancel?.call();
              Navigator.of(context).pop(false);
            },
            child: Text(config.cancelText ?? 'Cancel'),
          ),
        TextButton(
          onPressed: () {
            config.onConfirm?.call();
            Navigator.of(context).pop(true);
          },
          style: type == DialogType.error
              ? TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                )
              : null,
          child: Text(config.confirmText ?? 'OK'),
        ),
      ];
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: config.isDismissible && type != DialogType.loading,
      builder: (context) => PopScope(
        canPop: config.isDismissible && type != DialogType.loading,
        child: AlertDialog(
          title: buildTitle(),
          content: buildContent(),
          actions: buildActions(),
        ),
      ),
    );
  }

  // Convenience methods
  static Future<bool?> showAlert({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    bool isDismissible = true,
  }) {
    return showCustomDialog<bool>(
      context: context,
      type: DialogType.alert,
      config: DialogConfig(
        title: title,
        message: message,
        confirmText: confirmText,
        isDismissible: isDismissible,
      ),
    );
  }

  static Future<bool?> showConfirm({
    required BuildContext context,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDangerous = false,
  }) {
    return showCustomDialog<bool>(
      context: context,
      type: isDangerous ? DialogType.error : DialogType.confirm,
      config: DialogConfig(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }

  static Future<void> showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return showCustomDialog(
      context: context,
      type: DialogType.success,
      config: DialogConfig(
        title: title,
        message: message,
        confirmText: buttonText,
      ),
    );
  }

  static Future<void> showError({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return showCustomDialog(
      context: context,
      type: DialogType.error,
      config: DialogConfig(
        title: title,
        message: message,
        confirmText: buttonText,
      ),
    );
  }

  static Future<void> showWarning({
    required BuildContext context,
    required String title,
    required String message,
    String? buttonText,
  }) {
    return showCustomDialog(
      context: context,
      type: DialogType.warning,
      config: DialogConfig(
        title: title,
        message: message,
        confirmText: buttonText,
      ),
    );
  }

  static Future<void> showLoading({
    required BuildContext context,
    String title = 'Loading',
    String message = '',
  }) {
    return showCustomDialog(
      context: context,
      type: DialogType.loading,
      config: DialogConfig(
        title: title,
        message: message,
        isDismissible: false,
      ),
    );
  }

  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}
