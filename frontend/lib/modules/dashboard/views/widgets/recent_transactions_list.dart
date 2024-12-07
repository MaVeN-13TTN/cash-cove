import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/expense/expense_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../controllers/dashboard_controller.dart';

class RecentExpensesList extends StatelessWidget {
  final DashboardController controller;

  const RecentExpensesList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final expenses = controller.recentExpenses;

      if (expenses.isEmpty) {
        return const EmptyState(
          title: 'No Recent Expenses',
          description: 'Add an expense to see it here',
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: expenses.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return _ExpenseItem(
            expense: expenses[index],
          );
        },
      );
    });
  }
}

class _ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;

  const _ExpenseItem({
    Key? key,
    required this.expense,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildCategoryIcon(context),
      title: Text(
        expense.title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        expense.description ?? _getFormattedDate(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _buildAmount(context),
      onTap: () => _onExpenseTap(context),
    );
  }

  Widget _buildCategoryIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getCategoryIcon(),
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Widget _buildAmount(BuildContext context) {
    return Text(
      '\$${expense.amount.toStringAsFixed(2)}',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: expense.amount >= 0
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  String _getFormattedDate() {
    return '${expense.date.day}/${expense.date.month}/${expense.date.year}';
  }

  IconData _getCategoryIcon() {
    switch (expense.category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'health':
        return Icons.medical_services;
      default:
        return Icons.attach_money;
    }
  }

  void _onExpenseTap(BuildContext context) {
    Get.toNamed('/expenses/${expense.id}');
  }
}