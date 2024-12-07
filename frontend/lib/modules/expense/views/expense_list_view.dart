import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ignore: unused_import
import 'package:intl/intl.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../controllers/expense_controller.dart';
import 'add_expense_view.dart';
import 'widgets/expense_list_item.dart';
import 'widgets/expense_details_card.dart';

class ExpenseListView extends GetView<ExpenseController> {
  const ExpenseListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (controller.isLoading.value && controller.expenses.isEmpty) {
          return const LoadingState(message: 'Loading expenses...');
        }

        if (controller.error.value.isNotEmpty) {
          return ErrorState(
            title: 'Error',
            description: controller.error.value,
            onRetry: controller.fetchExpenses,
          );
        }

        if (controller.expenses.isEmpty) {
          return const EmptyState(
            title: 'No Expenses',
            description:
                'Start tracking your expenses by adding your first expense',
            icon: Icons.receipt_long,
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
                return ExpenseListItem(
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

  void _showExpenseDetails(dynamic expense) {
    Get.bottomSheet(
      ExpenseDetailsCard(
        expense: expense,
        onEdit: () {
          Get.back();
          Get.to(() => AddExpenseView(expense: expense));
        },
        onDelete: () {
          Get.back();
          controller.deleteExpense(expense.id);
        },
      ),
      isScrollControlled: true,
    );
  }
}
