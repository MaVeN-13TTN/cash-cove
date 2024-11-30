import 'dart:math' as math;
import 'package:flutter/material.dart';

class LineChartData {
  final String label;
  final double value;
  final String? tooltip;

  const LineChartData({
    required this.label,
    required this.value,
    this.tooltip,
  });
}

class LineChart extends StatefulWidget {
  final List<LineChartData> data;
  final Size size;
  final Color lineColor;
  final Color pointColor;
  final double strokeWidth;
  final bool showPoints;
  final bool showLabels;
  final bool showGrid;
  final Duration animationDuration;
  final Curve animationCurve;
  final String? semanticsLabel;
  final void Function(LineChartData)? onPointTap;

  const LineChart({
    super.key,
    required this.data,
    this.size = const Size(300, 200),
    this.lineColor = Colors.blue,
    this.pointColor = Colors.blue,
    this.strokeWidth = 2.0,
    this.showPoints = true,
    this.showLabels = true,
    this.showGrid = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeInOut,
    this.semanticsLabel,
    this.onPointTap,
  });

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  LineChartData? _selectedPoint;

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

  void _handleTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final points = _getPoints(
      widget.size,
      widget.size.height * 0.1,
      widget.data.map((e) => e.value).reduce(math.max),
      widget.data.map((e) => e.value).reduce(math.min),
      widget.data.map((e) => e.value).reduce(math.max) -
          widget.data.map((e) => e.value).reduce(math.min),
    );

    double minDistance = double.infinity;
    LineChartData? closestPoint;
    int index = 0;

    for (final point in points) {
      final distance = (point - localPosition).distance;
      if (distance < minDistance && distance < 20) {
        minDistance = distance;
        closestPoint = widget.data[index];
      }
      index++;
    }

    if (closestPoint != null) {
      setState(() => _selectedPoint = closestPoint);
      widget.onPointTap?.call(closestPoint);
    } else {
      setState(() => _selectedPoint = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox();

    final theme = Theme.of(context);

    return Semantics(
      label: widget.semanticsLabel ?? 'Line chart',
      child: Column(
        children: [
          GestureDetector(
            onTapDown: _handleTapDown,
            child: SizedBox(
              width: widget.size.width,
              height: widget.size.height,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LineChartPainter(
                      data: widget.data,
                      lineColor: widget.lineColor,
                      pointColor: widget.pointColor,
                      strokeWidth: widget.strokeWidth,
                      showPoints: widget.showPoints,
                      showGrid: widget.showGrid,
                      textStyle: theme.textTheme.bodySmall!,
                      gridColor: theme.dividerColor,
                      progress: _animation.value,
                      selectedPoint: _selectedPoint,
                    ),
                  );
                },
              ),
            ),
          ),
          if (widget.showLabels) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: widget.size.width,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: widget.data.map((point) {
                  return SizedBox(
                    width: widget.size.width / widget.data.length,
                    child: Text(
                      point.label,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Offset> _getPoints(Size size, double padding, double maxValue,
      double minValue, double range) {
    return List.generate(widget.data.length, (i) {
      final x = size.width * i / (widget.data.length - 1);
      final normalizedValue = (widget.data[i].value - minValue) / range;
      final y = size.height -
          (padding + normalizedValue * (size.height - 2 * padding));
      return Offset(x, y);
    });
  }
}

class _LineChartPainter extends CustomPainter {
  final List<LineChartData> data;
  final Color lineColor;
  final Color pointColor;
  final double strokeWidth;
  final bool showPoints;
  final bool showGrid;
  final TextStyle textStyle;
  final Color gridColor;
  final double progress;
  final LineChartData? selectedPoint;

  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.pointColor,
    required this.strokeWidth,
    required this.showPoints,
    required this.showGrid,
    required this.textStyle,
    required this.gridColor,
    required this.progress,
    this.selectedPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = data.map((e) => e.value).reduce(math.max);
    final minValue = data.map((e) => e.value).reduce(math.min);
    final range = maxValue - minValue;
    final padding = size.height * 0.1;

    if (showGrid) {
      _drawGrid(canvas, size, padding, maxValue, minValue, range);
    }

    final points = _getPoints(size, padding, maxValue, minValue, range);
    _drawLine(canvas, points);

    if (showPoints) {
      _drawPoints(canvas, points);
    }

    if (selectedPoint != null) {
      final index = data.indexOf(selectedPoint!);
      if (index != -1) {
        final point = points[index];
        _drawTooltip(canvas, point, selectedPoint!);
      }
    }
  }

  List<Offset> _getPoints(Size size, double padding, double maxValue,
      double minValue, double range) {
    return List.generate(data.length, (i) {
      final x = size.width * i / (data.length - 1);
      final normalizedValue = (data[i].value - minValue) / range;
      final y = size.height -
          (padding + normalizedValue * (size.height - 2 * padding));
      return Offset(x, y * progress);
    });
  }

  void _drawGrid(Canvas canvas, Size size, double padding, double maxValue,
      double minValue, double range) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    // Draw horizontal lines
    for (var i = 0; i <= 4; i++) {
      final y = padding + (size.height - 2 * padding) * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );

      // Draw value labels
      final value = maxValue - (range * i / 4);
      final textSpan = TextSpan(
        text: value.toStringAsFixed(1),
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width - 5, y - textPainter.height / 2),
      );
    }

    // Draw vertical lines
    for (var i = 0; i < data.length; i++) {
      final x = size.width * i / (data.length - 1);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  void _drawLine(Canvas canvas, List<Offset> points) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paint);
  }

  void _drawPoints(Canvas canvas, List<Offset> points) {
    final paint = Paint()
      ..color = pointColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    for (final point in points) {
      canvas.drawCircle(point, strokeWidth * 2, paint);
    }
  }

  void _drawTooltip(Canvas canvas, Offset point, LineChartData data) {
    final tooltipText = data.tooltip ?? '${data.label}: ${data.value}';
    final textSpan = TextSpan(
      text: tooltipText,
      style: textStyle.copyWith(
        color: Colors.white,
        fontSize: 12,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final tooltipWidth = textPainter.width + 16;
    final tooltipHeight = textPainter.height + 8;
    final tooltipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(
          point.dx,
          point.dy - tooltipHeight - 8,
        ),
        width: tooltipWidth,
        height: tooltipHeight,
      ),
      const Radius.circular(4),
    );

    canvas.drawRRect(
      tooltipRect,
      Paint()..color = Colors.black87,
    );

    textPainter.paint(
      canvas,
      Offset(
        point.dx - tooltipWidth / 2 + 8,
        point.dy - tooltipHeight - 8 + 4,
      ),
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.pointColor != pointColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showPoints != showPoints ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedPoint != selectedPoint;
  }
}