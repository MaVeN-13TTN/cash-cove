import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/validators.dart';
import '../../../data/models/budget/budget_model.dart';
import '../../../shared/widgets/custom_text_field.dart';
import '../controllers/budget_controller.dart';

class AddBudgetView extends GetView<BudgetController> {
  final BudgetModel? budget;
  final bool isEditing;
  final bool isModal;

  const AddBudgetView({
    Key? key, 
    this.budget,
    this.isModal = false,
  }) : isEditing = budget != null, super(key: key);

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: budget?.name);
    final amountController = TextEditingController(
      text: budget?.amount.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: budget?.description ?? '',
    );
    final startDateController = TextEditingController(
      text: budget?.startDate != null 
        ? DateFormat.yMd().format(budget!.startDate) 
        : '',
    );
    final endDateController = TextEditingController(
      text: budget?.endDate != null 
        ? DateFormat.yMd().format(budget!.endDate) 
        : '',
    );

    RxString selectedCategory = 
      (budget?.category ?? controller.budgetCategories.first).obs;
    Rx<DateTime> selectedStartDate = (budget?.startDate ?? DateTime.now()).obs;
    Rx<DateTime> selectedEndDate = (budget?.endDate ?? DateTime.now().add(const Duration(days: 30))).obs;

    return Scaffold(
      appBar: isModal ? null : AppBar(
        title: Text(isEditing ? 'Edit Budget' : 'Add Budget'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
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
          
          if (isModal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                isEditing ? 'Edit Budget' : 'Add Budget',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          
          const SizedBox(height: 16),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field
                    CustomTextField(
                      controller: nameController,
                      label: 'Name',
                      validator: Validators.requiredValidator,
                      prefixIcon: Icons.title,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Amount Field
                    CustomTextField(
                      controller: amountController,
                      label: 'Amount',
                      keyboardType: TextInputType.number,
                      validator: Validators.requiredValidator,
                      prefixIcon: Icons.attach_money,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Category Selector
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Obx(() => DropdownButton<String>(
                        value: selectedCategory.value,
                        isExpanded: true,
                        items: controller.budgetCategories
                          .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                          .toList(),
                        onChanged: (value) => selectedCategory.value = value!,
                      )),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Start Date Field
                    CustomTextField(
                      controller: startDateController,
                      label: 'Start Date',
                      readOnly: true,
                      validator: Validators.requiredValidator,
                      prefixIcon: Icons.calendar_today,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate.value,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          selectedStartDate.value = date;
                          startDateController.text = DateFormat.yMd().format(date);
                        }
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // End Date Field
                    CustomTextField(
                      controller: endDateController,
                      label: 'End Date',
                      readOnly: true,
                      validator: Validators.requiredValidator,
                      prefixIcon: Icons.calendar_today,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate.value,
                          firstDate: selectedStartDate.value,
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          selectedEndDate.value = date;
                          endDateController.text = DateFormat.yMd().format(date);
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
                    
                    const SizedBox(height: 24),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newBudget = BudgetModel(
                            id: budget?.id ?? '',
                            userId: budget?.userId ?? '',
                            name: nameController.text,
                            amount: double.parse(amountController.text),
                            category: selectedCategory.value,
                            startDate: selectedStartDate.value,
                            endDate: selectedEndDate.value,
                            description: descriptionController.text,
                            currency: 'USD',
                            remainingAmount: double.parse(amountController.text),
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            recurrence: 'Monthly',
                            notificationThreshold: 0.8,
                            isActive: true,
                            isExpired: false,
                            utilizationPercentage: 0.0,
                          );
                          
                          if (isEditing) {
                            // Update existing budget
                            controller.updateBudget(newBudget.id, newBudget.toJson());
                          } else {
                            // Add new budget
                            controller.createBudget(newBudget.toJson());
                          }
                          
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isEditing ? 'Update Budget' : 'Add Budget'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
