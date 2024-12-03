import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/transaction/transaction_model.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../controllers/dashboard_controller.dart';

class RecentTransactionsList extends StatelessWidget {
  final DashboardController controller;

  const RecentTransactionsList({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final transactions = controller.recentTransactions;

      if (transactions.isEmpty) {
        return const EmptyState(
          title: 'No Recent Transactions',
          description: 'Add a transaction to see it here',
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return _TransactionItem(
            transaction: transactions[index],
          );
        },
      );
    });
  }
}

class _TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionItem({
    Key? key,
    required this.transaction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _buildCategoryIcon(context),
      title: Text(
        transaction.description,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      subtitle: Text(
        _getFormattedDate(),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: _buildAmount(context),
      onTap: () => _onTransactionTap(context),
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

  Widget _buildAmount(BuildContext context) {
    return Text(
      '\$${transaction.amount.toStringAsFixed(2)}',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: transaction.amount < 0
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
    );
  }

  String _getFormattedDate() {
    return '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}';
  }

  IconData _getCategoryIcon() {
    switch (transaction.category.toLowerCase()) {
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

  void _onTransactionTap(BuildContext context) {
    Get.toNamed('/transactions/${transaction.id}');
  }
}