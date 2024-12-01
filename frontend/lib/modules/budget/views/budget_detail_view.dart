import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../data/models/budget/budget_category.dart';
import '../../../data/models/budget/budget_model.dart';
import '../controllers/budget_controller.dart';
import 'widgets/budget_form.dart';

class BudgetDetailView extends GetView<BudgetController> {
  final BudgetModel budget;

  const BudgetDetailView({
    Key? key,
    required this.budget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: budget.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditForm(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildProgressSection(context),
            const SizedBox(height: 24),
            _buildDetailsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final category = BudgetCategory.values.firstWhere(
      (cat) => cat.name == budget.category, 
      orElse: () => BudgetCategory.values.first
    );
    
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(int.parse(budget.color.substring(1, 7), radix: 16) + 0xFF000000),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.category,  
            color: Colors.white,
            size: 32,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${budget.amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final progress = controller.calculateBudgetProgress(budget);
    final remaining = budget.amount * (1 - progress);
    final spent = budget.amount * progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(
            Color(int.parse(budget.color.substring(1, 7), radix: 16) + 0xFF000000),
          ),
          minHeight: 8,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProgressCard(
              context,
              'Spent',
              '\$${spent.toStringAsFixed(2)}',
              '${(progress * 100).toStringAsFixed(1)}%',
            ),
            _buildProgressCard(
              context,
              'Remaining',
              '\$${remaining.toStringAsFixed(2)}',
              '${((1 - progress) * 100).toStringAsFixed(1)}%',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    String title,
    String amount,
    String percentage,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                amount,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                percentage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              _buildDetailTile(
                context,
                'Recurrence',
                budget.recurrence.toLowerCase().capitalize!,
              ),
              _buildDetailTile(
                context,
                'Start Date',
                budget.startDate.toString().split(' ')[0],
              ),
              _buildDetailTile(
                context,
                'End Date',
                budget.endDate.toString().split(' ')[0],
              ),
              _buildDetailTile(
                context,
                'Notification Threshold',
                '${budget.notificationThreshold}%',
              ),
              if (budget.description.isNotEmpty)
                _buildDetailTile(
                  context,
                  'Description',
                  budget.description,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailTile(BuildContext context, String title, String value) {
    return ListTile(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  void _showEditForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: SingleChildScrollView(
          child: BudgetForm(budget: budget),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Delete Budget',
        content: 'Are you sure you want to delete this budget? This action cannot be undone.',
        confirmText: 'Delete',
        onConfirm: () {
          Get.back();
          controller.deleteBudget(budget.id);
        },
      ),
    );
  }
}