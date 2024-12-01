import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/expense_controller.dart';

class AddExpenseView extends GetView<ExpenseController> {
  final ExpenseModel? expense;
  final bool isEditing;

  const AddExpenseView({
    Key? key, 
    this.expense,
  }) : isEditing = expense != null, super(key: key);

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: expense?.title);
    final amountController = TextEditingController(
      text: expense?.amount.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: expense?.description ?? '',
    );
    final dateController = TextEditingController(
      text: expense?.date != null 
        ? DateFormat.yMd().format(expense!.date) 
        : '',
    );

    RxString selectedCategory = 
      (expense?.category ?? controller.expenseCategories.first).obs;
    Rx<DateTime> selectedDate = (expense?.date ?? DateTime.now()).obs;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Obx(() => Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: titleController,
              label: 'Title',
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
            DropdownButtonFormField<String>(
              value: selectedCategory.value,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
                border: OutlineInputBorder(),
              ),
              items: controller.expenseCategories
                .map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                ))
                .toList(),
              onChanged: (value) => selectedCategory.value = value!,
            ),
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
              onPressed: () => _saveExpense(
                formKey,
                titleController,
                amountController,
                descriptionController,
                selectedCategory.value,
                selectedDate.value,
              ),
              child: Text(isEditing ? 'Update Expense' : 'Add Expense'),
            ),
          ],
        ),
      )),
    );
  }

  void _saveExpense(
    GlobalKey<FormState> formKey,
    TextEditingController titleController,
    TextEditingController amountController,
    TextEditingController descriptionController,
    String category,
    DateTime selectedDate,
  ) async {
    if (formKey.currentState!.validate()) {
      final expenseModel = ExpenseModel(
        id: isEditing ? expense!.id : const Uuid().v4(),
        userId: 'current_user_id', // TODO: Replace with actual user ID
        title: titleController.text,
        amount: double.parse(amountController.text),
        currency: 'USD', // TODO: Make dynamic
        date: selectedDate,
        category: category,
        description: descriptionController.text.isEmpty 
          ? null 
          : descriptionController.text,
        attachments: null, // TODO: Implement attachment upload
        createdAt: isEditing ? expense!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        budgetId: null, // Optional budget association
      );

      final result = isEditing 
        ? await controller.updateExpense(expenseModel)
        : await controller.createExpense(expenseModel);

      if (result != null) {
        Get.back(); // Close the form
        Get.snackbar(
          'Success', 
          isEditing 
            ? 'Expense updated successfully' 
            : 'Expense added successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}