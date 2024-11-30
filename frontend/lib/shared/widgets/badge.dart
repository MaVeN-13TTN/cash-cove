import 'package:flutter/material.dart';
import 'package:budget_tracker/shared/theme/app_colors.dart';

enum BadgeVariant {
  primary,
  success,
  warning,
  error,
  info,
}

class Badge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final bool outlined;
  final double? size;
  final String? semanticsLabel;

  const Badge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.outlined = false,
    this.size,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color backgroundColor;
    Color textColor;

    switch (variant) {
      case BadgeVariant.primary:
        backgroundColor = theme.colorScheme.primary;
        textColor = theme.colorScheme.onPrimary;
        break;
      case BadgeVariant.success:
        backgroundColor = theme.extension<AppColors>()?.success ?? Colors.green;
        textColor = Colors.white;
        break;
      case BadgeVariant.warning:
        backgroundColor = theme.extension<AppColors>()?.warning ?? Colors.orange;
        textColor = Colors.white;
        break;
      case BadgeVariant.error:
        backgroundColor = theme.colorScheme.error;
        textColor = theme.colorScheme.onError;
        break;
      case BadgeVariant.info:
        backgroundColor = theme.extension<AppColors>()?.info ?? Colors.blue;
        textColor = Colors.white;
        break;
    }

    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: outlined ? backgroundColor : textColor,
      fontSize: size ?? 12,
    );

    return Semantics(
      label: semanticsLabel ?? text,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: (size ?? 12) * 0.75,
          vertical: (size ?? 12) * 0.25,
        ),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : backgroundColor,
          border: outlined
              ? Border.all(
                  color: backgroundColor,
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular((size ?? 12) * 2),
        ),
        child: Text(
          text,
          style: textStyle,
        ),
      ),
    );
  }
}
