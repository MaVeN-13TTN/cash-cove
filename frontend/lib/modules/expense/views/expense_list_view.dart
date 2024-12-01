import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../controllers/expense_controller.dart';
import 'add_expense_view.dart';

class ExpenseListView extends GetView<ExpenseController> {
  const ExpenseListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.expenses.isEmpty) {
          return const LoadingState(message: 'Loading expenses...');
        }

        if (controller.error.value.isNotEmpty) {
          return ErrorState(
            message: controller.error.value,
            onRetry: controller.fetchExpenses,
          );
        }

        if (controller.expenses.isEmpty) {
          return EmptyState(
            message: 'No expenses found',
            suggestion: 'Add your first expense',
            onActionPressed: () => Get.to(() => const AddExpenseView()),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchExpenses,
          child: ListView.separated(
            itemCount: controller.expenses.length + 
              (controller.hasMoreExpenses.value ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              if (index < controller.expenses.length) {
                final expense = controller.expenses[index];
                return _ExpenseListItem(
                  expense: expense,
                  onTap: () => _showExpenseDetails(expense),
                );
              } else {
                // Load more indicator
                return _buildLoadMoreIndicator();
              }
            },
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const AddExpenseView()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return controller.hasMoreExpenses.value
        ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          )
        : const SizedBox.shrink();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Obx(() => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filter Expenses',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Wrap(
            spacing: 8,
            children: controller.expenseCategories
              .map((category) => ChoiceChip(
                label: Text(category),
                selected: false,
                onSelected: (selected) {
                  // TODO: Implement category filtering
                  Navigator.pop(context);
                },
              ))
              .toList(),
          ),
        ],
      )),
    );
  }

  void _showExpenseDetails(dynamic expense) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Get.theme.cardColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize MainAxisSize.min,
          children: [
            Text(
              expense.title,
              style: Get.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${expense.amount.toStringAsFixed(2)}',
              style: Get.textTheme.titleMedium?.copyWith(
                color: expense.amount < 0 
                  ? Get.theme.colorScheme.error 
                  : Get.theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text('Category: ${expense.category}'),
            Text('Date: ${DateFormat.yMMMd().format(expense.date)}'),
            if (expense.description != null)
              Text('Description: ${expense.description}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                    Get.to(() => AddExpenseView(expense: expense));
                  },
                  child: const Text('Edit'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Get.theme.colorScheme.error,
                  ),
                  onPressed: () {
                    Get.back();
                    controller.deleteExpense(expense.id);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final dynamic expense;
  final VoidCallback onTap;

  const _ExpenseListItem({
    Key? key,
    required this.expense,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildCategoryIcon(context),
      title: Text(expense.title),
      subtitle: Text(DateFormat.yMMMd().format(expense.date)),
      trailing: Text(
        '\$${expense.amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: expense.amount < 0 
            ? Theme.of(context).colorScheme.error 
            : Theme.of(context).colorScheme.primary,
        ),
      ),
      onTap: onTap,
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
}