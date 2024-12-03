import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/expense_controller.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/storage/file_upload_service.dart';

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
    RxList<File> attachments = <File>[].obs;

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
            const SizedBox(height: 16),
            // Attachment upload section
            ElevatedButton.icon(
              onPressed: () => _pickAttachments(attachments),
              icon: const Icon(Icons.attach_file),
              label: const Text('Add Attachments'),
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
            ElevatedButton(
              onPressed: () => _saveExpense(
                formKey,
                titleController,
                amountController,
                descriptionController,
                selectedCategory.value,
                selectedDate.value,
                attachments,
              ),
              child: Text(isEditing ? 'Update Expense' : 'Add Expense'),
            ),
          ],
        ),
      )),
    );
  }

  // Method to pick attachments
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
  ) async {
    if (formKey.currentState!.validate()) {
      // Get current user ID from AuthService
      final String? userId = Get.find<AuthService>().currentUser;

      // Determine currency based on current locale
      final String currency = 
        NumberFormat.simpleCurrency().currencySymbol;

      // Upload attachments
      final List<String>? uploadedAttachments = attachments.isNotEmpty
        ? await _uploadAttachments(attachments)
        : null;

      final expenseData = {
        'id': isEditing ? expense!.id : const Uuid().v4(),
        'userId': userId ?? 'unknown_user', // Fallback if no user ID
        'title': titleController.text,
        'amount': double.parse(amountController.text),
        'currency': currency,
        'date': selectedDate,
        'category': category,
        'description': descriptionController.text.isEmpty 
          ? null 
          : descriptionController.text,
        'attachments': uploadedAttachments,
        'createdAt': isEditing ? expense!.createdAt : DateTime.now(),
        'updatedAt': DateTime.now(),
        'budgetId': null, // Optional budget association
      };

      try {
        if (isEditing) {
          await controller.updateExpense(expenseData['id'] as String, expenseData);
        } else {
          await controller.createExpense(expenseData);
        }

        Get.back(); // Close the form
        Get.snackbar(
          'Success', 
          isEditing 
            ? 'Expense updated successfully' 
            : 'Expense added successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } catch (e) {
        Get.snackbar(
          'Error', 
          'Failed to ${isEditing ? 'update' : 'add'} expense',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Method to upload attachments
  Future<List<String>?> _uploadAttachments(RxList<File> files) async {
    try {
      final fileUploadService = Get.find<FileUploadService>();
      final List<String> uploadedFiles = await fileUploadService.uploadFiles(files.toList());
      return uploadedFiles.map((fileId) => fileUploadService.getDownloadUrl(fileId)).toList();
    } catch (e) {
      Get.snackbar(
        'Upload Error', 
        'Failed to upload attachments',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    }
  }
}