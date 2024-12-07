import 'package:flutter/material.dart';
import '../../../data/models/shared_expense/shared_expense_model.dart';

class SharedExpenseDetailsView extends StatelessWidget {
  final SharedExpenseModel expense;

  const SharedExpenseDetailsView({Key? key, required this.expense}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(expense.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${expense.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Status: ${expense.status.toString().split('.').last}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Description: ${expense.description}',
                style: Theme.of(context).textTheme.bodyMedium),
            // Add more fields as necessary
          ],
        ),
      ),
    );
  }
}
