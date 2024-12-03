import 'package:flutter/material.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final bool hasBorder;
  final Widget? content;

  const InfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.backgroundColor,
    this.padding,
    this.hasBorder = false,
    this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: content ?? Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );

    final card = Material(
      color: backgroundColor ?? theme.cardTheme.color,
      elevation: theme.cardTheme.elevation ?? 0,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: hasBorder
            ? BoxDecoration(
                border: Border.all(
                  color: theme.dividerColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: cardContent,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}