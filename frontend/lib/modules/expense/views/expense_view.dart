import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/app_bar.dart';
import '../../shared_expenses/views/shared_expenses_view.dart';
import '../controllers/expense_controller.dart';

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Expenses',
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Personal'),
              Tab(text: 'Shared'),
            ],
            indicatorColor: theme.primaryColor,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
          ),
        ),
        body: TabBarView(
          children: [
            _buildPersonalExpenses(),
            const SharedExpensesView(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Builder(
      builder: (context) {
        final tabController = DefaultTabController.of(context);
        return AnimatedBuilder(
          animation: tabController,
          builder: (context, child) {
            if (tabController.index == 1) {
              // Shared expenses tab
              return FloatingActionButton(
                onPressed: () => Get.toNamed('/shared-expenses/create'),
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.group_add),
              );
            }
            
            // Personal expenses tab
            return FloatingActionButton(
              onPressed: () => Get.toNamed('/expenses/create'),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonalExpenses() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.expenses.isEmpty) {
        return Center(
          child: Text(
            'No expenses yet',
            style: Get.textTheme.titleMedium,
          ),
        );
      }

      return ListView.builder(
        itemCount: controller.expenses.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final expense = controller.expenses[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                  Icons.receipt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                expense.title,
                style: Get.textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: Get.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (expense.description != null)
                    Text(
                      expense.description!,
                      style: Get.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              trailing: Text(
                '\$${expense.amount.toStringAsFixed(2)}',
                style: Get.textTheme.titleMedium?.copyWith(
                  color: expense.amount > 0 ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => Get.toNamed('/expenses/${expense.id}'),
            ),
          );
        },
      );
    });
  }
}
