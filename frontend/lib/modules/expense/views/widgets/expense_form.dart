import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../../core/utils/validators.dart';
import '../../../../../data/models/expense/expense_model.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../controllers/expense_controller.dart';
import 'expense_category_selector.dart';

class ExpenseForm extends StatelessWidget {
  final ExpenseModel? initialExpense;
  final Function(ExpenseModel) onSubmit;

  const ExpenseForm({
    Key? key, 
    this.initialExpense, 
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.find();
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: initialExpense?.title ?? '',
    );
    final amountController = TextEditingController(
      text: initialExpense?.amount.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: initialExpense?.description ?? '',
    );
    final dateController = TextEditingController(
      text: initialExpense?.date != null 
        ? DateFormat.yMd().format(initialExpense!.date) 
        : '',
    );

    final RxString selectedCategory = 
      (initialExpense?.category ?? controller.expenseCategories.first).obs;
    final Rx<DateTime> selectedDate = 
      (initialExpense?.date ?? DateTime.now()).obs;

    return Form(
      key: formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: titleController,
            label: 'Expense Title',
            validator: Validators.requiredValidator,
            prefixIcon: Icons.title,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: amountController,
            label: 'Amount',
            keyboardType: TextInputType.number,
            validator: Validators.amountValidator,
            prefixIcon: Icons.attach_money,
          ),
          const SizedBox(height: 16),
          Obx(() => ExpenseCategorySelector(
            initialCategory: selectedCategory.value,
            onCategorySelected: (category) {
              selectedCategory.value = category;
            },
          )),
          const SizedBox(height: 16),
          CustomTextField(
            controller: dateController,
            label: 'Date',
            readOnly: true,
            validator: Validators.requiredValidator,
            prefixIcon: Icons.calendar_today,
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate.value,
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                selectedDate.value = pickedDate;
                dateController.text = 
                  DateFormat.yMd().format(pickedDate);
              }
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: descriptionController,
            label: 'Description (Optional)',
            maxLines: 3,
            prefixIcon: Icons.description,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final expenseModel = ExpenseModel(
                  id: initialExpense?.id ?? const Uuid().v4(),
                  userId: 'current_user_id', // TODO: Replace with actual user ID
                  title: titleController.text,
                  amount: double.parse(amountController.text),
                  currency: 'USD', // TODO: Make dynamic
                  date: selectedDate.value,
                  category: selectedCategory.value,
                  description: descriptionController.text.isEmpty 
                    ? null 
                    : descriptionController.text,
                  attachments: null, // TODO: Implement attachment upload
                  createdAt: initialExpense?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  budgetId: null, // Optional budget association
                );

                onSubmit(expenseModel);
              }
            },
            child: Text(
              initialExpense == null 
                ? 'Add Expense' 
                : 'Update Expense',
            ),
          ),
        ],
      ),
    );
  }
}