import 'package:flutter/material.dart';

class Skeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Duration shimmerDuration;
  final Color? baseColor;
  final Color? highlightColor;
  final String? semanticsLabel;

  const Skeleton({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
    this.shimmerDuration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
    this.semanticsLabel,
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.shimmerDuration,
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = widget.baseColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey[300]
            : Colors.grey[700]);
    final highlightColor = widget.highlightColor ??
        (theme.brightness == Brightness.light
            ? Colors.grey[100]
            : Colors.grey[600]);

    return Semantics(
      label: widget.semanticsLabel ?? 'Loading',
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  baseColor!,
                  highlightColor!,
                  baseColor,
                ],
                stops: [
                  0.0,
                  _animation.value,
                  1.0,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final int lines;
  final double spacing;
  final double? width;
  final bool randomWidths;
  final String? semanticsLabel;

  const SkeletonText({
    super.key,
    this.lines = 3,
    this.spacing = 8,
    this.width,
    this.randomWidths = true,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? 'Loading text',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lines,
          (index) {
            double lineWidth = width ?? double.infinity;
            if (randomWidths && width == null) {
              final lastLine = index == lines - 1;
              lineWidth = lastLine
                  ? MediaQuery.of(context).size.width * 0.5
                  : MediaQuery.of(context).size.width *
                      (0.8 + index * 0.1).clamp(0.0, 1.0);
            }

            return Padding(
              padding: EdgeInsets.only(bottom: index == lines - 1 ? 0 : spacing),
              child: Skeleton(
                width: lineWidth,
                height: 16,
              ),
            );
          },
        ),
      ),
    );
  }
}

class SkeletonAvatar extends StatelessWidget {
  final double size;
  final String? semanticsLabel;

  const SkeletonAvatar({
    super.key,
    this.size = 48,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
      semanticsLabel: semanticsLabel ?? 'Loading avatar',
    );
  }
}

class SkeletonCard extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;

  const SkeletonCard({
    super.key,
    this.width = double.infinity,
    this.height = 200,
    this.padding = const EdgeInsets.all(16),
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? 'Loading card',
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonAvatar(size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(width: 120, height: 16),
                      SizedBox(height: 8),
                      Skeleton(width: 80, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: Skeleton(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
