import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double value;
  final double max;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final Widget? label;
  final bool showPercentage;

  const BudgetProgressBar({
    super.key,
    required this.value,
    required this.max,
    this.color,
    this.backgroundColor,
    this.height = 8.0,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (value / max).clamp(0.0, 1.0);
    final progressColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.colorScheme.primary.withOpacity(0.12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          label!,
          const SizedBox(height: 8),
        ],
        Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(percentage * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
            ),
          ),
        ],
      ],
    );
  }
}

class CircularBudgetProgress extends StatelessWidget {
  final double value;
  final double max;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double strokeWidth;
  final Widget? child;

  const CircularBudgetProgress({
    super.key,
    required this.value,
    required this.max,
    this.color,
    this.backgroundColor,
    this.size = 100.0,
    this.strokeWidth = 8.0,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (value / max).clamp(0.0, 1.0);
    final progressColor = color ?? theme.colorScheme.primary;
    final bgColor = backgroundColor ?? theme.colorScheme.primary.withOpacity(0.12);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: 1.0,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(bgColor),
          ),
          CircularProgressIndicator(
            value: percentage,
            strokeWidth: strokeWidth,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
          if (child != null)
            Center(child: child!),
        ],
      ),
    );
  }
}

class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;

  const LoadingSpinner({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}
