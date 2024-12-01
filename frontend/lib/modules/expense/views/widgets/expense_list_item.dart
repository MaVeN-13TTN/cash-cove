import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/expense/expense_model.dart';

class ExpenseListItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseListItem({
    Key? key,
    required this.expense,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildLeadingIcon(context),
      title: Text(
        expense.title,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        DateFormat.yMMMd().format(expense.date),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _buildTrailingAmount(context),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  Widget _buildLeadingIcon(BuildContext context) {
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

  Widget _buildTrailingAmount(BuildContext context) {
    return Text(
      '\$${expense.amount.toStringAsFixed(2)}',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: expense.amount < 0
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
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
