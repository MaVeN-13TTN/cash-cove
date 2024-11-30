import 'package:flutter/material.dart';

extension BuildContextExtension on BuildContext {
  // Theme extensions
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  
  // Media Query extensions
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
  EdgeInsets get padding => mediaQuery.padding;
  EdgeInsets get viewInsets => mediaQuery.viewInsets;
  
  // Responsive breakpoints
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;
  
  // Navigation extensions
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) =>
      Navigator.of(this).pushNamed<T>(routeName, arguments: arguments);
  
  // Snackbar helper
  void showSnackBar(String message, {
    Duration duration = const Duration(seconds: 2),
    Color? backgroundColor,
    Color? textColor,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: textTheme.bodyMedium?.copyWith(
            color: textColor ?? colors.onPrimary,
          ),
        ),
        duration: duration,
        backgroundColor: backgroundColor ?? colors.primary,
      ),
    );
  }
  
  // Dialog helper
  Future<T?> showAppDialog<T>({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<T>(
      context: this,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () {
                context.pop();
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
          if (confirmText != null)
            TextButton(
              onPressed: () {
                context.pop();
                onConfirm?.call();
              },
              child: Text(confirmText),
            ),
        ],
      ),
    );
  }
  
  // Bottom sheet helper
  Future<T?> showAppBottomSheet<T>({
    required Widget child,
    bool isDismissible = true,
    Color? backgroundColor,
    double? heightFactor,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      backgroundColor: backgroundColor ?? colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => heightFactor != null
          ? FractionallySizedBox(
              heightFactor: heightFactor,
              child: child,
            )
          : child,
    );
  }
}
