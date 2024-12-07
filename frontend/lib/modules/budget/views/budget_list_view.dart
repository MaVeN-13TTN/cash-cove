import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/error_state.dart';
import '../../../shared/widgets/loading_state.dart';
import '../../../shared/widgets/custom_filter_chip.dart';
import '../../../data/models/budget/budget_category.dart';
import '../controllers/budget_controller.dart';
import 'widgets/budget_form.dart';
import 'budget_detail_view.dart';

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
          _buildCategoryFilter(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading) {
                return const LoadingState(
                  message: 'Please wait while we fetch your budgets',
                );
              }

              if (controller.error != null) {
                return ErrorState(
                  title: 'Error Loading Budgets',
                  description: controller.error?.toString() ?? 'An error occurred',
                  onRetry: controller.fetchBudgets,
                );
              }

              final budgets = controller.getFilteredBudgets();
              if (budgets.isEmpty) {
                return const EmptyState(
                  icon: Icons.account_balance_wallet,
                  title: 'No Budgets',
                  description: 'Create your first budget to start tracking expenses',
                );
              }

              return RefreshIndicator(
                onRefresh: controller.fetchBudgets,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final budget = budgets[index];
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
                                      color: Color(int.parse(budget.color.substring(1, 7), radix: 16) + 0xFF000000),
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
                                  Color(int.parse(budget.color.substring(1, 7), radix: 16) + 0xFF000000),
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
                  },
                ),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CustomFilterChip(
            label: 'All',
            isSelected: controller.selectedCategory == null,
            onSelected: () {
              controller.setSelectedCategory(null);
            },
          ),
          const SizedBox(width: 8),
          ...BudgetCategory.values.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: CustomFilterChip(
                label: category.displayName,
                isSelected: controller.selectedCategory == category.name,
                onSelected: () {
                  if (controller.selectedCategory != category.name) {
                    controller.setSelectedCategory(category.name);
                  } else {
                    controller.setSelectedCategory(null);
                  }
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showBudgetForm(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Material(
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                      top: 16,
                      left: 16,
                      right: 16,
                    ),
                    child: const BudgetForm(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),  // Slide from top
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
          ),
          child: child,
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    final budgetCategory = BudgetCategory.values
        .firstWhere(
          (c) => c.name == category,
          orElse: () => BudgetCategory.custom,
        );
    
    // Convert emoji to IconData
    switch (budgetCategory) {
      case BudgetCategory.monthly:
        return Icons.calendar_month;
      case BudgetCategory.weekly:
        return Icons.calendar_view_week;
      case BudgetCategory.yearly:
        return Icons.calendar_today;
      case BudgetCategory.custom:
        return Icons.settings;
    }
  }

  String _getCategoryDisplayName(String category) {
    return BudgetCategory.values
        .firstWhere(
          (c) => c.name == category,
          orElse: () => BudgetCategory.custom,
        )
        .displayName;
  }

  void _showDateRangePicker(BuildContext context) async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
      initialDateRange: controller.dateRange,
    );

    if (dateRange != null) {
      controller.setDateRange(dateRange);
    }
  }
}
