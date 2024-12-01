import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/analytics_controller.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/utils/animation_utils.dart';
import '../../../../shared/theme/app_colors.dart';

class SpendingChart extends GetView<AnalyticsController> {
  const SpendingChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final gridColor = brightness == Brightness.light
        ? Colors.black.withOpacity(0.1)
        : Colors.white.withOpacity(0.1);
    final labelColor = brightness == Brightness.light
        ? Colors.black.withOpacity(0.8)
        : Colors.white.withOpacity(0.8);

    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Spending Trend',
              style: Theme.of(context).textTheme.titleLarge,
              semanticsLabel: 'Monthly spending trend line chart',
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: ResponsiveUtils.isMobile(context) ? 200 : 300,
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.error.value.isNotEmpty) {
                  return Center(
                    child: Text(
                      controller.error.value,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                final monthlyData = controller.monthlySpending;
                if (monthlyData.isEmpty) {
                  return Center(
                    child: Text(
                      'No spending data available',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return AnimatedSwitcher(
                  duration: AnimationUtils.defaultDuration,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 1,
                        verticalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: gridColor,
                          strokeWidth: 1,
                        ),
                        getDrawingVerticalLine: (value) => FlLine(
                          color: gridColor,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: 1,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                _getMonthLabel(value.toInt()),
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: ResponsiveUtils.isMobile(context) ? 10 : 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: _calculateInterval(monthlyData),
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                '\$${value.toInt()}',
                                style: TextStyle(
                                  color: labelColor,
                                  fontSize: ResponsiveUtils.isMobile(context) ? 10 : 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: gridColor),
                      ),
                      minX: 0,
                      maxX: monthlyData.length - 1,
                      minY: 0,
                      maxY: _calculateMaxY(monthlyData),
                      lineBarsData: [
                        LineChartBarData(
                          spots: monthlyData.asMap().entries.map((entry) {
                            return FlSpot(entry.key.toDouble(), entry.value);
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).extension<AppColors>()?.info ?? Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: (Theme.of(context).extension<AppColors>()?.info ?? Colors.blue).withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthLabel(int index) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final monthIndex = (now.month - 6 + index) % 12;
    return months[monthIndex];
  }

  double _calculateInterval(List<double> data) {
    final maxValue = _calculateMaxY(data);
    return maxValue / 5;
  }

  double _calculateMaxY(List<double> data) {
    if (data.isEmpty) return 1000;
    final maxValue = data.reduce((curr, next) => curr > next ? curr : next);
    return maxValue + (maxValue * 0.2);
  }
}
