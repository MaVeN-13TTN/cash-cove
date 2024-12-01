import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/budget/budget_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../core/utils/snackbar_utils.dart';

class BudgetController extends GetxController {
  final BudgetRepository _repository;
  
  BudgetController({
    required BudgetRepository repository,
  }) : _repository = repository;

  // Observable states
  final _budgets = <BudgetModel>[].obs;
  final _isLoading = false.obs;
  final _selectedCategory = Rx<String?>(null);
  final _dateRange = Rx<DateTimeRange?>(null);
  final _error = Rx<String?>(null);

  // Getters
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading.value;
  String? get selectedCategory => _selectedCategory.value;
  DateTimeRange? get dateRange => _dateRange.value;
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    fetchBudgets();
  }

  Future<void> fetchBudgets() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final result = await _repository.getBudgets();
      _budgets.assignAll(result);
    } catch (e) {
      _error.value = 'Failed to load budgets';
      SnackbarUtils.showError('Error', 'Failed to load budgets');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> createBudget(BudgetModel budget) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await _repository.createBudget({
        'name': budget.name,
        'amount': budget.amount,
        'userId': budget.userId,
        'currency': budget.currency,
        'startDate': budget.startDate.toIso8601String(),
        'endDate': budget.endDate.toIso8601String(),
        'category': budget.category,
        'spentAmount': budget.spentAmount,
        'createdAt': budget.createdAt.toIso8601String(),
        'updatedAt': budget.updatedAt.toIso8601String(),
      });
      await fetchBudgets();
      Get.back();
      SnackbarUtils.showSuccess('Success', 'Budget created successfully');
    } catch (e) {
      _error.value = 'Failed to create budget';
      SnackbarUtils.showError('Error', 'Failed to create budget');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateBudget(BudgetModel budget) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await _repository.updateBudget(budget.id, {
        'name': budget.name,
        'amount': budget.amount,
        'userId': budget.userId,
        'currency': budget.currency,
        'startDate': budget.startDate.toIso8601String(),
        'endDate': budget.endDate.toIso8601String(),
        'category': budget.category,
        'spentAmount': budget.spentAmount,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await fetchBudgets();
      Get.back();
      SnackbarUtils.showSuccess('Success', 'Budget updated successfully');
    } catch (e) {
      _error.value = 'Failed to update budget';
      SnackbarUtils.showError('Error', 'Failed to update budget');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await _repository.deleteBudget(id);
      await fetchBudgets();
      SnackbarUtils.showSuccess('Success', 'Budget deleted successfully');
    } catch (e) {
      _error.value = 'Failed to delete budget';
      SnackbarUtils.showError('Error', 'Failed to delete budget');
    } finally {
      _isLoading.value = false;
    }
  }

  void setSelectedCategory(String? category) {
    _selectedCategory.value = category;
    fetchBudgets();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange.value = range;
    fetchBudgets();
  }

  List<BudgetModel> getFilteredBudgets() {
    var filtered = _budgets.toList();
    
    if (_selectedCategory.value != null) {
      filtered = filtered.where((b) => b.category == _selectedCategory.value).toList();
    }
    
    if (_dateRange.value != null) {
      filtered = filtered.where((b) {
        return (b.startDate.isAfter(_dateRange.value!.start) || 
                b.startDate.isAtSameMomentAs(_dateRange.value!.start)) &&
               (b.endDate.isBefore(_dateRange.value!.end) || 
                b.endDate.isAtSameMomentAs(_dateRange.value!.end));
      }).toList();
    }
    
    return filtered;
  }

  double calculateTotalBudget() {
    return getFilteredBudgets().fold(0, (sum, budget) => sum + budget.amount);
  }

  double calculateBudgetProgress(BudgetModel budget) {
    return budget.spentPercentage / 100;
  }
}