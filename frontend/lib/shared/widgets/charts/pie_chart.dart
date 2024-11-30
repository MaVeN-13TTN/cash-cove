import 'dart:math' as math;
import 'package:flutter/material.dart';

class PieChartData {
  final String label;
  final double value;
  final Color color;
  final String? tooltip;

  const PieChartData({
    required this.label,
    required this.value,
    required this.color,
    this.tooltip,
  });
}

class PieChart extends StatefulWidget {
  final List<PieChartData> data;
  final double size;
  final double strokeWidth;
  final Widget? centerWidget;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool showLabels;
  final String? semanticsLabel;

  const PieChart({
    super.key,
    required this.data,
    this.size = 200,
    this.strokeWidth = 20,
    this.centerWidget,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeInOut,
    this.showLabels = true,
    this.semanticsLabel,
  });

  @override
  State<PieChart> createState() => _PieChartState();
}

class _PieChartState extends State<PieChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.animationCurve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.data.fold<double>(0, (sum, item) => sum + item.value);

    return Semantics(
      label: widget.semanticsLabel ?? 'Pie chart',
      child: Column(
        children: [
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              children: [
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(widget.size, widget.size),
                      painter: _PieChartPainter(
                        data: widget.data,
                        total: total,
                        strokeWidth: widget.strokeWidth,
                        progress: _animation.value,
                      ),
                    );
                  },
                ),
                if (widget.centerWidget != null)
                  Positioned.fill(
                    child: Center(child: widget.centerWidget!),
                  ),
              ],
            ),
          ),
          if (widget.showLabels) ...[
            const SizedBox(height: 16),
            PieChartLegend(
              data: widget.data,
              total: total,
            ),
          ],
        ],
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PieChartData> data;
  final double total;
  final double strokeWidth;
  final double progress;

  _PieChartPainter({
    required this.data,
    required this.total,
    required this.strokeWidth,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    var startAngle = -math.pi / 2;

    for (final item in data) {
      final sweepAngle = 2 * math.pi * (item.value / total) * progress;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = item.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.total != total ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progress != progress;
  }
}

class PieChartLegend extends StatelessWidget {
  final List<PieChartData> data;
  final double total;

  const PieChartLegend({
    super.key,
    required this.data,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.map((item) {
        final percentage = (item.value / total * 100).toStringAsFixed(1);
        return Tooltip(
          message: item.tooltip ?? '${item.label}: $percentage%',
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}