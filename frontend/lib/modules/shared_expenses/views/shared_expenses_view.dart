import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/shared_expenses/shared_expenses_service.dart';
import '../../../data/models/shared_expense/shared_expense_model.dart';
import 'shared_expense_details_view.dart';

class SharedExpensesView extends StatefulWidget {
  const SharedExpensesView({Key? key}) : super(key: key);

  @override
  State<SharedExpensesView> createState() => _SharedExpensesViewState();
}

class _SharedExpensesViewState extends State<SharedExpensesView> {
  final SharedExpensesService _sharedExpensesService = Get.find();

  @override
  void initState() {
    super.initState();
    _sharedExpensesService.fetchSharedExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = _sharedExpensesService.isLoading.value;
      final error = _sharedExpensesService.error.value;
      final sharedExpenses = _sharedExpensesService.sharedExpenses;

      if (isLoading) {
        return const Center(child: CircularProgressIndicator());
      }

      if (error.isNotEmpty) {
        return Center(
          child: Text(
            'Error loading shared expenses: $error',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red),
          ),
        );
      }

      if (sharedExpenses.isEmpty) {
        return const Center(
          child: Text('No shared expenses found'),
        );
      }

      return ListView.builder(
        itemCount: sharedExpenses.length,
        itemBuilder: (context, index) {
          final SharedExpenseModel expense = sharedExpenses[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(expense.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: \$${expense.amount.toStringAsFixed(2)}'),
                  Text('Status: ${expense.status.toString().split('.').last}'),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Get.to(() => SharedExpenseDetailsView(expense: expense));
                },
              ),
            ),
          );
        },
      );
    });
  }
}