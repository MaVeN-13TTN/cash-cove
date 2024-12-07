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
    String? budgetId,
  }) async {
    if (!await checkExpensesExist()) {
      // No expenses exist, fallback to empty state
      expenses.clear();
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;
      error.value = '';

      if (!loadMore) {
        _page = 1;
        currentPage.value = 1;
        expenses.clear();
      } else {
        _page++;
        currentPage.value++;
      }

      final fetchedExpenses = await _repository.getExpenses(
        startDate: startDate,
        endDate: endDate,
        category: category,
        budgetId: budgetId,
      );

      if (loadMore) {
        expenses.addAll(fetchedExpenses);
      } else {
        expenses.assignAll(fetchedExpenses);
      }

      hasMoreExpenses.value = fetchedExpenses.isNotEmpty;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
      hasMoreExpenses.value = false;
      currentPage.value = _page - 1; // Revert page on error
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
