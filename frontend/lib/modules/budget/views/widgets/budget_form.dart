import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dropdown.dart';
import '../../../../shared/widgets/custom_date_picker.dart';
import '../../../../data/models/budget/budget_model.dart';
import '../../../../data/models/budget/budget_category.dart';
import '../../controllers/budget_controller.dart';
import '../../../../core/services/auth/auth_service.dart';

class BudgetForm extends StatefulWidget {
  final BudgetModel? budget;

  const BudgetForm({Key? key, this.budget}) : super(key: key);

  @override
  State<BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends State<BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final AuthService _authService;
  
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCategory = BudgetCategory.monthly.name;
  String _selectedRecurrence = 'Monthly';
  double _notificationThreshold = 0.8;
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    _authService = Get.find<AuthService>();
    if (widget.budget != null) {
      _nameController.text = widget.budget!.name;
      _amountController.text = widget.budget!.amount.toString();
      _descriptionController.text = widget.budget!.description;
      _selectedCategory = widget.budget!.category;
      _selectedRecurrence = widget.budget!.recurrence;
      _startDate = widget.budget!.startDate;
      _endDate = widget.budget!.endDate;
      _notificationThreshold = widget.budget!.notificationThreshold;
      if (widget.budget!.color != null) {
        _selectedColor = Color(int.parse(widget.budget!.color!.substring(1, 7), radix: 16) + 0xFF000000);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {
        'name': _nameController.text,
        'amount': double.parse(_amountController.text),
        'category': _selectedCategory,
        'description': _descriptionController.text,
        'startDate': _startDate ?? DateTime.now(),
        'endDate': _endDate ?? DateTime.now().add(const Duration(days: 30)),
        'userId': _authService.currentUser ?? 'default_user',
        'currency': _authService.displayName.isEmpty ? 'USD' : 'KES',
        'recurrence': _selectedRecurrence,
        'notificationThreshold': _notificationThreshold,
        'color': '#${_selectedColor.value.toRadixString(16).substring(2)}',
        'isActive': true,
        'isExpired': false,
        'remainingAmount': double.parse(_amountController.text),
        'utilizationPercentage': 0.0,
      };

      final controller = Get.find<BudgetController>();
      if (widget.budget != null) {
        controller.updateBudget(widget.budget!.id, data);
      } else {
        controller.createBudget(data);
      }

      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Budget Name',
            validator: Validators.required,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _amountController,
            label: 'Amount',
            keyboardType: TextInputType.number,
            validator: Validators.validateAmount,
          ),
          const SizedBox(height: 16),
          CustomDropdown<String>(
            label: 'Category',
            value: _selectedCategory,
            items: BudgetCategory.values.map((e) => e.name).toList(),
            displayText: (value) => BudgetCategory.values
                .firstWhere((e) => e.name == value)
                .displayName,
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _descriptionController,
            label: 'Description',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomDatePicker(
                  label: 'Start Date',
                  initialDate: _startDate,
                  onDateSelected: (date) => setState(() => _startDate = date),
                  validator: Validators.validateDate,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomDatePicker(
                  label: 'End Date',
                  initialDate: _endDate,
                  onDateSelected: (date) => setState(() => _endDate = date),
                  validator: Validators.validateDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text(widget.budget != null ? 'Update Budget' : 'Create Budget'),
          ),
          const SizedBox(height: 32),  
        ],
      ),
    );
  }
}