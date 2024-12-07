import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_controller.dart';
import 'expense_list_view.dart';
import 'add_expense_view.dart';

class ExpenseView extends GetView<ExpenseController> {
  const ExpenseView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: const Text('Expenses'),
              pinned: true,
              floating: true,
              bottom: TabBar(
                tabs: const [
                  Tab(text: 'Personal'),
                ],
                indicatorColor: theme.primaryColor,
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.grey,
              ),
            ),
          ],
          body: const TabBarView(
            children: [
              ExpenseListView(),
            ],
          ),
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
            // Personal expenses tab
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  heroTag: 'filter',
                  onPressed: () => _showFilterBottomSheet(context),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  child: const Icon(Icons.filter_list),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: 'add',
                  onPressed: () => _showAddExpenseForm(context),
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.add),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Obx(() => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filter Expenses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color, // Ensure readability
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Category Chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: controller.expenseCategories
                .map((category) => ChoiceChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      color: controller.selectedCategory.value == category 
                        ? Colors.white  // White text when selected
                        : Theme.of(context).textTheme.bodyLarge?.color, // Default text color
                    ),
                  ),
                  selected: controller.selectedCategory.value == category,
                  onSelected: (selected) {
                    controller.selectedCategory.value = 
                      selected ? category : null;
                    
                    // Fetch expenses with selected category
                    controller.fetchExpenses(
                      category: controller.selectedCategory.value
                    );
                    
                    Navigator.pop(context);
                  },
                  selectedColor: Theme.of(context).primaryColor.withOpacity(0.8),
                  backgroundColor: Colors.grey[200],
                ))
                .toList(),
            ),
            
            const SizedBox(height: 16),
            
            // Clear Filter Button
            if (controller.selectedCategory.value != null)
              ElevatedButton(
                onPressed: () {
                  controller.selectedCategory.value = null;
                  controller.fetchExpenses(); // Fetch all expenses
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white, // White text on button
                ),
                child: const Text('Clear Filter'),
              ),
          ],
        ),
      )),
    );
  }

  void _showAddExpenseForm(BuildContext context) {
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
                    child: const AddExpenseView(isModal: true),
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
}
