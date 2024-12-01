import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/expense_controller.dart';

class ExpenseCategorySelector extends StatelessWidget {
  final ValueChanged<String> onCategorySelected;
  final String? initialCategory;

  const ExpenseCategorySelector({
    Key? key,
    required this.onCategorySelected,
    this.initialCategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ExpenseController controller = Get.find();
    final RxString selectedCategory = 
      (initialCategory ?? controller.expenseCategories.first).obs;

    return Obx(() => DropdownButtonFormField<String>(
      value: selectedCategory.value,
      decoration: const InputDecoration(
        labelText: 'Expense Category',
        prefixIcon: Icon(Icons.category),
        border: OutlineInputBorder(),
      ),
      items: controller.expenseCategories
        .map((category) => DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              _getCategoryIcon(category),
              const SizedBox(width: 10),
              Text(category),
            ],
          ),
        ))
        .toList(),
      onChanged: (value) {
        if (value != null) {
          selectedCategory.value = value;
          onCategorySelected(value);
        }
      },
    ));
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'food':
        icon = Icons.restaurant;
        break;
      case 'transport':
        icon = Icons.directions_car;
        break;
      case 'shopping':
        icon = Icons.shopping_bag;
        break;
      case 'entertainment':
        icon = Icons.movie;
        break;
      case 'bills':
        icon = Icons.receipt;
        break;
      case 'health':
        icon = Icons.medical_services;
        break;
      default:
        icon = Icons.attach_money;
    }
    return Icon(icon, color: Get.theme.colorScheme.primary);
  }
}
