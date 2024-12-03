import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../controllers/dashboard_controller.dart';
import 'widgets/budget_summary_card.dart';
import 'widgets/recent_transactions_list.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshDashboard,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingState(
            message: 'Loading dashboard data...',
          );
        }

        if (controller.error != null) {
          return ErrorState.message(
            message: controller.error!,
            onRetry: controller.refreshDashboard,
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BudgetSummaryCard(controller: controller),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Recent Transactions'),
                const SizedBox(height: 16),
                RecentTransactionsList(controller: controller),
                const SizedBox(height: 24),
                _buildQuickActions(context),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/transactions/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, 'Quick Actions'),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              context,
              icon: Icons.add_chart,
              label: 'New Budget',
              onTap: () => Get.toNamed('/budgets/create'),
            ),
            _buildActionButton(
              context,
              icon: Icons.receipt_long,
              label: 'All Transactions',
              onTap: () => Get.toNamed('/transactions'),
            ),
            _buildActionButton(
              context,
              icon: Icons.analytics,
              label: 'Analytics',
              onTap: () => Get.toNamed('/analytics'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}