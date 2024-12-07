import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../controllers/dashboard_controller.dart';
import 'package:intl/intl.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  DashboardViewState createState() => DashboardViewState();
}

class DashboardViewState extends State<DashboardView> with WidgetsBindingObserver {
  final DashboardController controller = Get.find();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      controller.fetchDashboardData();
    }
  }

  String _getSpendingAdvice() {
    if (controller.isUsingDummyData) {
      return 'Loading your personalized spending advice...';
    }

    final daysLeft = DateUtils.getDaysInMonth(
          DateTime.now().year,
          DateTime.now().month,
        ) -
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshDashboard(),
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
            onRetry: () => controller.refreshDashboard(),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => controller.refreshDashboard(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBudgetSummaryCard(context),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Recent Expenses'),
                const SizedBox(height: 16),
                _buildRecentExpensesList(context),
                const SizedBox(height: 24),
                _buildQuickActions(context),
              ],
            ),
          ),
        );
      }),
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

  Widget _buildBudgetSummaryCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${controller.totalBudget.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBudgetStat(
                context,
                'Spent',
                '\$${controller.totalSpent.toStringAsFixed(2)}',
              ),
              _buildBudgetStat(
                context,
                'Remaining',
                '\$${controller.remainingBudget.toStringAsFixed(2)}',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  controller.remainingBudget < 0
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getSpendingAdvice(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildRecentExpensesList(BuildContext context) {
    if (controller.recentExpenses.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Expenses Yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start tracking your expenses by adding your first expense',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.recentExpenses.take(5).length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final expense = controller.recentExpenses[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _getTransactionIcon(expense.category),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              expense.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            subtitle: Text(
              DateFormat('MMM d, y').format(expense.date),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            trailing: Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: expense.amount > 0
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                  ),
            ),
          );
        },
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
              icon: Icons.add_circle_outline,
              label: 'Add Expense',
              onTap: () => Get.toNamed('/expenses/add'),
            ),
            _buildActionButton(
              context,
              icon: Icons.pie_chart_outline,
              label: 'View Reports',
              onTap: () => Get.toNamed('/reports'),
            ),
            _buildActionButton(
              context,
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => Get.toNamed('/settings'),
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
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTransactionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'groceries':
        return Icons.shopping_cart;
      case 'transportation':
        return Icons.directions_car;
      case 'utilities':
        return Icons.lightbulb;
      case 'entertainment':
        return Icons.movie;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'shopping':
        return Icons.shopping_bag;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.receipt;
    }
  }
}