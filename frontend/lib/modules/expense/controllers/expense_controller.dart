import 'package:get/get.dart';

import '../../../../data/models/expense/expense_model.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../core/utils/error_handler.dart';

class ExpenseController extends GetxController {
  final ExpenseRepository _repository;

  // Constructor with optional repository
  ExpenseController({ExpenseRepository? repository}) 
      : _repository = repository ?? Get.find<ExpenseRepository>();

  // Observables
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final Rx<ExpenseModel?> selectedExpense = Rx<ExpenseModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final Rx<String?> selectedCategory = Rx<String?>(null);

  // Expense categories
  final RxList<String> expenseCategories = [
    'Food',
    'Transport',
    'Entertainment',
    'Shopping',
    'Bills',
    'Health',
    'Other'
  ].obs;

  // Pagination
  int _page = 1;
  final RxBool hasMoreExpenses = true.obs;
  final RxInt currentPage = 1.obs;

  // Check if expenses exist for the user
  Future<bool> checkExpensesExist() async {
    try {
      final existingExpenses = await _repository.getExpenses();
      return existingExpenses.isNotEmpty;
    } catch (e) {
      ErrorHandler.handleError(e);
      return false;
    }
  }

  // Fetch expenses
  Future<void> fetchExpenses({
    bool loadMore = false,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      // Use the passed category or the selected category from the observable
      final effectiveCategory = category ?? selectedCategory.value;

      isLoading.value = true;
      
      // If loadMore is true, increment page, otherwise reset to first page
      _page = loadMore ? _page + 1 : 1;

      final fetchedExpenses = await _repository.getExpenses(
        page: _page,
        category: effectiveCategory,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );

      // If not loading more, clear existing expenses
      if (!loadMore) {
        expenses.clear();
      }

      // Add new expenses
      expenses.addAll(fetchedExpenses);

      // Update pagination state
      hasMoreExpenses.value = fetchedExpenses.isNotEmpty;
      currentPage.value = _page;

    } catch (e) {
      ErrorHandler.handleError(e);
      hasMoreExpenses.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  // Create expense
  Future<void> createExpense(Map<String, dynamic> expenseData) async {
    try {
      isLoading.value = true;
      error.value = '';

      final createdExpense = await _repository.createExpense(expenseData);
      expenses.insert(0, createdExpense);
      selectedExpense.value = createdExpense;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Update expense
  Future<void> updateExpense(String id, Map<String, dynamic> expenseData) async {
    try {
      isLoading.value = true;
      error.value = '';

      final updatedExpense = await _repository.updateExpense(id, expenseData);
      final index = expenses.indexWhere((e) => e.id == updatedExpense.id);
      if (index != -1) {
        expenses[index] = updatedExpense;
      }
      selectedExpense.value = updatedExpense;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _repository.deleteExpense(expenseId);
      expenses.removeWhere((expense) => expense.id == expenseId);
      selectedExpense.value = null;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  // Get expense by ID
  Future<void> getExpenseById(String expenseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final expense = await _repository.getExpense(expenseId);
      selectedExpense.value = expense;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchExpenses();
  }
}
