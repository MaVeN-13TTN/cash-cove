import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/analytics_controller.dart';
import 'widgets/spending_chart.dart';
import 'widgets/budget_progress_chart.dart';
import '../../../shared/utils/responsive_utils.dart';
import '../../../shared/utils/animation_utils.dart';

class AnalyticsView extends GetView<AnalyticsController> {
  const AnalyticsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshData,
            tooltip: 'Refresh analytics data',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getResponsivePadding(context),
          child: Column(
            children: [
              if (ResponsiveUtils.isDesktop(context))
                _buildDesktopLayout(context)
              else if (ResponsiveUtils.isTablet(context))
                _buildTabletLayout(context)
              else
                _buildMobileLayout(context),
              const SizedBox(height: 16),
              Builder(
                builder: (context) => _buildTopSpendingCategories(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSummaryCard(context),
            ),
            const SizedBox(width: 24),
            const Expanded(
              flex: 3,
              child: SpendingChart(),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const BudgetProgressChart(),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildSummaryCard(context)),
          ],
        ),
        const SizedBox(height: 24),
        const SpendingChart(),
        const SizedBox(height: 24),
        const BudgetProgressChart(),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildSummaryCard(context),
        const SizedBox(height: 16),
        const SpendingChart(),
        const SizedBox(height: 16),
        const BudgetProgressChart(),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Financial Summary',
              style: Theme.of(context).textTheme.titleLarge,
              semanticsLabel: 'Financial summary showing income, expenses, and net balance',
            ),
            const SizedBox(height: 16),
            Obx(() {
              final summaryItems = [
                _SummaryItem(
                  title: 'Income',
                  amount: controller.totalIncome.value,
                  icon: Icons.arrow_upward,
                  color: Theme.of(context).colorScheme.primary,
                ),
                _SummaryItem(
                  title: 'Expenses',
                  amount: controller.totalExpenses.value,
                  icon: Icons.arrow_downward,
                  color: Theme.of(context).colorScheme.error,
                ),
                _SummaryItem(
                  title: 'Net',
                  amount: controller.totalIncome.value - controller.totalExpenses.value,
                  icon: (controller.totalIncome.value - controller.totalExpenses.value) >= 0
                      ? Icons.check_circle
                      : Icons.warning,
                  color: (controller.totalIncome.value - controller.totalExpenses.value) >= 0
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.error,
                ),
              ];

              return Builder(
                builder: (innerContext) => ResponsiveUtils.isMobile(innerContext)
                  ? Column(
                      children: summaryItems
                          .map((item) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildSummaryItem(innerContext, item),
                              ))
                          .toList(),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: summaryItems
                          .map((item) => Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: _buildSummaryItem(innerContext, item),
                                ),
                              ))
                          .toList(),
                    ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, _SummaryItem item) {
    return AnimatedOpacity(
      duration: AnimationUtils.defaultDuration,
      opacity: controller.isLoading.value ? 0.5 : 1.0,
      child: Column(
        children: [
          Icon(item.icon, color: item.color, size: 28),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '\$${item.amount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: item.color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpendingCategories(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: ResponsiveUtils.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Spending Categories',
              style: Theme.of(context).textTheme.titleLarge,
              semanticsLabel: 'List of categories with highest spending',
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = controller.topSpendingCategories;
              if (categories.isEmpty) {
                return Center(
                  child: Text(
                    'No spending data available',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                );
              }

              return Builder(
                builder: (innerContext) => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (_, index) {
                    final entry = categories[index];
                    final percentage = (entry.value / controller.totalExpenses.value) * 100;
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(innerContext).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                '\$${entry.value.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
                                style: Theme.of(innerContext).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            duration: AnimationUtils.defaultDuration,
                            curve: AnimationUtils.defaultCurve,
                            tween: Tween<double>(
                              begin: 0,
                              end: percentage / 100,
                            ),
                            builder: (_, value, __) => LinearProgressIndicator(
                              value: value,
                              backgroundColor: Theme.of(innerContext).colorScheme.surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(innerContext).colorScheme.primary,
                              ),
                              minHeight: ResponsiveUtils.isMobile(innerContext) ? 8 : 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });
}