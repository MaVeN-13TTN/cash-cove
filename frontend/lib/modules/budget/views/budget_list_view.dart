import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/budget/budget_model.dart';
import '../../../data/models/budget/budget_category.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/custom_filter_chip.dart';
import '../../../shared/utils/response_handler.dart';
import '../controllers/budget_controller.dart';
import 'widgets/budget_form.dart';
import 'budget_detail_view.dart';
import 'add_budget_view.dart';

class BudgetListView extends GetView<BudgetController> {
  const BudgetListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () => _showDateRangePicker(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryFilter(context),
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const LoadingState(message: 'Loading budgets...');
              }

              if (controller.error != null) {
                return ErrorState(
                  title: 'Error Loading Budgets',
                  description: controller.error?.toString() ?? 'An error occurred',
                  onRetry: controller.fetchBudgets,
                );
              }

              return ResponseHandler.handleEmptyResponse(
                data: controller.getFilteredBudgets(),
                type: 'budgets',
                onAction: () => _showBudgetForm(context),
                onData: (data) => _buildBudgetList(context, data),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_budget_fab',
        onPressed: () => Get.to(() => const AddBudgetView(isModal: true)),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context) {
    return Obx(() => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CustomFilterChip(
            label: 'All',
            isSelected: controller.selectedCategory == null,
            onSelected: () => controller.selectedCategory = null,
          ),
          const SizedBox(width: 8),
          ...BudgetCategory.values.map((category) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CustomFilterChip(
              label: category.name,
              isSelected: controller.selectedCategory == category.name,
              onSelected: () => controller.selectedCategory = category.name,
            ),
          )).toList(),
        ],
      ),
    ));
  }

  Widget _buildBudgetList(BuildContext context, List<BudgetModel> budgets) {
    return RefreshIndicator(
      onRefresh: () => controller.fetchBudgets(),
      child: ListView.builder(
        itemCount: budgets.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final budget = budgets[index];
          return _buildBudgetCard(context, budget);
        },
      ),
    );
  }

  Widget _buildBudgetCard(BuildContext context, BudgetModel budget) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => Get.to(() => BudgetDetailView(budget: budget)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: budget.color != null 
                        ? Color(int.parse(budget.color!.substring(1, 7), radix: 16) + 0xFF000000)
                        : Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(budget.category),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          budget.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _getCategoryDisplayName(budget.category),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${budget.amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        budget.recurrence.toLowerCase().capitalize!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: controller.calculateBudgetProgress(budget),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  budget.color != null
                    ? Color(int.parse(budget.color!.substring(1, 7), radix: 16) + 0xFF000000)
                    : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress: ${(controller.calculateBudgetProgress(budget) * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Remaining: \$${(budget.amount * (1 - controller.calculateBudgetProgress(budget))).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBudgetForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Budget',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const BudgetForm(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'HOUSING':
        return Icons.home;
      case 'TRANSPORTATION':
        return Icons.directions_car;
      case 'FOOD':
        return Icons.restaurant;
      case 'UTILITIES':
        return Icons.power;
      case 'HEALTHCARE':
        return Icons.local_hospital;
      case 'ENTERTAINMENT':
        return Icons.movie;
      case 'SHOPPING':
        return Icons.shopping_cart;
      case 'EDUCATION':
        return Icons.school;
      case 'SAVINGS':
        return Icons.savings;
      default:
        return Icons.category;
    }
  }

  String _getCategoryDisplayName(String category) {
    return category.toLowerCase().capitalize ?? category;
  }

  void _showDateRangePicker(BuildContext context) {
    // Implement date range picker
  }
}
