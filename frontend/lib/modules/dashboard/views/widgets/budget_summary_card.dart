import 'package:flutter/material.dart';
import '../../../../shared/widgets/cards/info_card.dart';
import '../../controllers/dashboard_controller.dart';

class BudgetSummaryCard extends StatelessWidget {
  final DashboardController controller;

  const BudgetSummaryCard({
    Key? key,
    required this.controller,
  }) : super(key: key);

  String _getSpendingAdvice() {
    if (controller.isUsingDummyData) {
      return 'Loading your personalized spending advice...';
    }

    final daysLeft = DateTime.now().month == 12
        ? DateTime(DateTime.now().year, 12, 31).day - DateTime.now().day
        : DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day -
            DateTime.now().day;
    final dailyBudget = controller.remainingBudget / daysLeft;

    if (controller.remainingBudget <= 0) {
      return 'You have exceeded your budget. Try to reduce spending.';
    } else if (controller.spendingPercentage > 90) {
      return 'You are close to your budget limit. Be careful with spending.';
    } else if (controller.spendingPercentage > 75) {
      return 'You can spend about \$${dailyBudget.toStringAsFixed(2)} per day for the rest of the month.';
    } else {
      return 'You are well within your budget. Keep it up!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      title: 'Budget Summary',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressIndicator(context),
          const SizedBox(height: 16),
          _buildAmountRow(context),
          const SizedBox(height: 8),
          _buildAdviceText(context),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Spent',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${controller.spendingPercentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _getProgressColor(context),
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: controller.spendingPercentage / 100,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAmountRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Budget',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '\$${controller.totalBudget.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Remaining',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '\$${controller.remainingBudget.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getProgressColor(context),
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdviceText(BuildContext context) {
    return Text(
      _getSpendingAdvice(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
          ),
    );
  }

  Color _getProgressColor(BuildContext context) {
    final percentage = controller.spendingPercentage;
    if (percentage >= 100) {
      return Theme.of(context).colorScheme.error;
    } else if (percentage >= 90) {
      return Colors.orange;
    } else if (percentage >= 75) {
      return Colors.yellow.shade700;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
}