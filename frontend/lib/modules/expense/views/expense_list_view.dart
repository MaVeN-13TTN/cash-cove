import 'package:flutter/material.dart';
import 'package:get/get.dart';
// ignore: unused_import
import 'package:intl/intl.dart';

import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/utils/response_handler.dart';
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

        return ResponseHandler.handleEmptyResponse(
          data: controller.expenses,
          type: 'expenses',
          onData: (data) => _buildExpenseList(data),
        );
      }),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_expense_fab',
        onPressed: () => Get.to(() => const AddExpenseView()),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildExpenseList(List expenses) {
    return RefreshIndicator(
      onRefresh: controller.fetchExpenses,
      child: ListView.separated(
        itemCount: expenses.length + (controller.hasMoreExpenses.value ? 1 : 0),
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          if (index < expenses.length) {
            final expense = expenses[index];
            return ExpenseListItem(
              expense: expense,
              onTap: () => _showExpenseDetails(expense),
            );
          } else {
            // Show loading indicator at the bottom for pagination
            if (controller.isLoading.value) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  void _showExpenseDetails(expense) {
    showModalBottomSheet(
      context: Get.context!,
      isScrollControlled: true,
      builder: (context) => ExpenseDetailsCard(expense: expense),
    );
  }
}
