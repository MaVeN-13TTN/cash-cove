import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../controllers/analytics_controller.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/utils/animation_utils.dart';
import '../../../../shared/theme/app_colors.dart';

class BudgetProgressChart extends GetView<AnalyticsController> {
  const BudgetProgressChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Progress',
              style: Theme.of(context).textTheme.titleLarge,
              semanticsLabel:
                  'Budget progress chart showing spending vs budget',
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Builder(
                builder: (context) => AnimatedSwitcher(
                  duration: AnimationUtils.defaultDuration,
                  child: _buildChart(context),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final spendingData = controller.spendingPercentages;
    if (spendingData.isEmpty) {
      return Center(
        child: Text(
          'No spending data available',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return Column(
      children: spendingData.asMap().entries.map((entry) {
        final index = entry.key;
        final entryValue = entry.value;
        final radius = ResponsiveUtils.isMobile(context) ? 50.0 : 60.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entryValue.key,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${entryValue.value.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: radius * 2,
                child: TweenAnimationBuilder<double>(
                  duration: AnimationUtils.defaultDuration,
                  curve: AnimationUtils.defaultCurve,
                  tween: Tween<double>(
                    begin: 0,
                    end: entryValue.value,
                  ),
                  builder: (context, value, child) => PieChart(
                    PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 0,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                          value: value,
                          color: _getCategoryColor(context, index),
                          title: '${value.toStringAsFixed(1)}%',
                          radius: radius,
                          titleStyle: TextStyle(
                            fontSize:
                                ResponsiveUtils.isMobile(context) ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        PieChartSectionData(
                          value: 100 - value,
                          color: _getCategoryColor(context, index)
                              .withOpacity(0.3),
                          title: '',
                          radius: radius * 0.8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getCategoryColor(BuildContext context, int index) {
    final colors = [
      Theme.of(context).extension<AppColors>()?.info ?? Colors.blue,
      Theme.of(context).extension<AppColors>()?.success ?? Colors.green,
      Theme.of(context).extension<AppColors>()?.warning ?? Colors.orange,
      Theme.of(context).extension<AppColors>()?.info.withOpacity(0.8) ??
          Colors.blue.withOpacity(0.8),
      Theme.of(context).extension<AppColors>()?.success.withOpacity(0.8) ??
          Colors.green.withOpacity(0.8),
    ];
    return colors[index % colors.length];
  }
}
