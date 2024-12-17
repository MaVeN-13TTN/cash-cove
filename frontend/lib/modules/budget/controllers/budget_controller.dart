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
  final _forecast = Rx<Map<String, dynamic>?>(null);
  final _utilization = RxMap<String, Map<String, dynamic>>({});

  // Getters
  List<BudgetModel> get budgets => _budgets;
  bool get isLoading => _isLoading.value;
  String? get selectedCategory => _selectedCategory.value;
  DateTimeRange? get dateRange => _dateRange.value;
  String? get error => _error.value;
  Map<String, dynamic>? get forecast => _forecast.value;
  Map<String, Map<String, dynamic>> get utilization => _utilization;
  List<String> get budgetCategories => ['Food', 'Transport', 'Utilities', 'Entertainment', 'Healthcare'];

  // Setters
  set selectedCategory(String? value) => _selectedCategory.value = value;
  set dateRange(DateTimeRange? value) => _dateRange.value = value;

  // Filter methods
  List<BudgetModel> getFilteredBudgets() {
    return _budgets.where((budget) {
      // Apply category filter
      if (selectedCategory != null && budget.category != selectedCategory) {
        return false;
      }

      // Apply date range filter
      if (dateRange != null) {
        final budgetStart = budget.startDate;
        final budgetEnd = budget.endDate;
        
        // Check if budget period overlaps with selected date range
        if (budgetEnd.isBefore(dateRange!.start) || 
            budgetStart.isAfter(dateRange!.end)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // Update filter methods
  void updateSelectedCategory(String? category) {
    _selectedCategory.value = category;
  }

  void updateDateRange(DateTimeRange? range) {
    _dateRange.value = range;
  }

  @override
  void onInit() {
    super.onInit();
    fetchBudgets();
    fetchForecast();
  }

  Future<void> fetchBudgets() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final result = await _repository.getBudgets();
      _budgets.assignAll(result);
      
      // Fetch utilization for each budget
      for (var budget in result) {
        fetchBudgetUtilization(budget.id);
      }
    } catch (e) {
      _error.value = 'Failed to load budgets';
      SnackbarUtils.showError('Error', 'Failed to load budgets');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> fetchForecast() async {
    try {
      final result = await _repository.getBudgetForecast();
      _forecast.value = result;
    } catch (e) {
      SnackbarUtils.showError('Error', 'Failed to load budget forecast');
    }
  }

  Future<void> fetchBudgetUtilization(String budgetId) async {
    try {
      final result = await _repository.getBudgetUtilization(budgetId);
      _utilization[budgetId] = result;
    } catch (e) {
      // Silent failure for utilization
      _utilization[budgetId] = {};
    }
  }

  Future<void> createBudget(Map<String, dynamic> data) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      
      // Validate budget data
      if (!_validateBudgetData(data)) {
        throw Exception('Invalid budget data');
      }
      
      final budget = await _repository.createBudget(data);
      _budgets.add(budget);
      Get.back(); // Close the create budget form
      SnackbarUtils.showSuccess('Success', 'Budget created successfully');
      
      // Fetch utilization for the new budget
      fetchBudgetUtilization(budget.id);
    } catch (e) {
      _error.value = 'Failed to create budget';
      SnackbarUtils.showError('Error', 'Failed to create budget');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateBudget(String id, Map<String, dynamic> data) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      
      // Validate budget data
      if (!_validateBudgetData(data)) {
        throw Exception('Invalid budget data');
      }
      
      final budget = await _repository.updateBudget(id, data);
      final index = _budgets.indexWhere((b) => b.id == id);
      if (index != -1) {
        _budgets[index] = budget;
      }
      Get.back(); // Close the edit budget form
      SnackbarUtils.showSuccess('Success', 'Budget updated successfully');
      
      // Refresh utilization
      fetchBudgetUtilization(id);
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
      _budgets.removeWhere((b) => b.id == id);
      _utilization.remove(id);
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
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange.value = range;
  }

  bool _validateBudgetData(Map<String, dynamic> data) {
    if (!data.containsKey('name') || (data['name'] as String).isEmpty) {
      return false;
    }
    if (!data.containsKey('amount') || (data['amount'] as num) <= 0) {
      return false;
    }
    if (!data.containsKey('category') || (data['category'] as String).isEmpty) {
      return false;
    }
    if (!data.containsKey('start_date') || !data.containsKey('end_date')) {
      return false;
    }
    
    // Validate dates
    final startDate = data['start_date'] is DateTime 
        ? data['start_date'] as DateTime 
        : DateTime.parse(data['start_date'] as String);
    final endDate = data['end_date'] is DateTime 
        ? data['end_date'] as DateTime 
        : DateTime.parse(data['end_date'] as String);
    
    if (endDate.isBefore(startDate)) {
      return false;
    }
    
    return true;
  }

  double calculateBudgetProgress(BudgetModel budget) {
    final utilizationData = _utilization[budget.id];
    if (utilizationData == null || !utilizationData.containsKey('utilizationPercentage')) {
      return 0.0;
    }
    
    final utilization = utilizationData['utilizationPercentage'] as num;
    return (utilization / 100).clamp(0.0, 1.0);
  }

  // Handle budget threshold notifications
  void checkBudgetThresholds() {
    for (var budget in _budgets) {
      final utilData = _utilization[budget.id];
      if (utilData != null) {
        final utilizationPercentage = budget.utilizationPercentage;
        if (utilizationPercentage >= budget.notificationThreshold) {
          SnackbarUtils.showWarning(
            'Budget Alert',
            'Budget "${budget.name}" has reached ${utilizationPercentage.toStringAsFixed(1)}% of its limit'
          );
        }
      }
    }
  }
}