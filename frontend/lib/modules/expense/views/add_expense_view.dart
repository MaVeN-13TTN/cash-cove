import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/expense_controller.dart';
import 'widgets/expense_category_selector.dart';

class AddExpenseView extends GetView<ExpenseController> {
  final ExpenseModel? expense;
  final bool isEditing;
  final bool isModal;

  const AddExpenseView({
    Key? key, 
    this.expense,
    this.isModal = false,
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
    RxList<File> attachments = <File>[].obs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isModal)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            isEditing ? 'Edit Expense' : 'Add Expense',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color, // Ensure readability
                ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 16),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Field
                CustomTextField(
                  controller: titleController,
                  label: 'Title',
                  validator: Validators.requiredValidator,
                  prefixIcon: Icons.title,
                ),
                
                const SizedBox(height: 16),
                
                // Amount Field
                CustomTextField(
                  controller: amountController,
                  label: 'Amount',
                  keyboardType: TextInputType.number,
                  validator: Validators.amountValidator,
                  prefixIcon: Icons.attach_money,
                ),
                
                const SizedBox(height: 16),
                
                // Expense Category Selector
                ExpenseCategorySelector(
                  initialCategory: selectedCategory.value,
                  onCategorySelected: (category) {
                    selectedCategory.value = category;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Date Picker
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
                
                // Description Field
                CustomTextField(
                  controller: descriptionController,
                  label: 'Description (Optional)',
                  maxLines: 3,
                  prefixIcon: Icons.description,
                ),
                
                const SizedBox(height: 16),
                
                // Attachment upload section
                ElevatedButton.icon(
                  onPressed: () => _pickAttachments(attachments),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add Attachments'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, // White text
                  ),
                ),
                if (attachments.isNotEmpty)
                  Column(
                    children: attachments.map((file) => 
                      ListTile(
                        title: Text(file.path.split('/').last),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => attachments.remove(file),
                        ),
                      )
                    ).toList(),
                  ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _saveExpense(
                        formKey,
                        titleController,
                        amountController,
                        descriptionController,
                        selectedCategory.value,
                        selectedDate.value,
                        attachments,
                      );
                      if (isModal) Get.back(); // Close modal if opened as a modal
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white, // White text on button
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Update Expense' : 'Add Expense',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Explicit white text
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _pickAttachments(RxList<File> attachments) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      allowMultiple: true,
    );

    if (result != null) {
      attachments.addAll(
        result.paths.map((path) => File(path!)).toList()
      );
    }
  }

  void _saveExpense(
      GlobalKey<FormState> formKey,
      TextEditingController titleController,
      TextEditingController amountController,
      TextEditingController descriptionController,
      String category,
      DateTime selectedDate,
      RxList<File> attachments,
    ) {
      final expenseData = {
        'title': titleController.text,
        'amount': double.tryParse(amountController.text) ?? 0.0,
        'description': descriptionController.text,
        'category': category,
        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
        'attachments': attachments.map((file) => file.path).toList(),
      };

      if (isEditing) {
        controller.updateExpense(expense!.id.toString(), expenseData);
      } else {
        controller.createExpense(expenseData);
      }
    }
}