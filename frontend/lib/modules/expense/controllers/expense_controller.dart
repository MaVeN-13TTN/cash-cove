import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../../../data/models/expense/expense_model.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/utils/error_handler.dart';

class ExpenseController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Observables
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final Rx<ExpenseModel?> selectedExpense = Rx<ExpenseModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  // Pagination
  int _page = 1;
  final RxBool hasMoreExpenses = true.obs;

  // Fetch expenses
  Future<void> fetchExpenses({
    bool loadMore = false,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      isLoading.value = true;
      error.value = '';

      if (!loadMore) {
        _page = 1;
        expenses.clear();
      }

      final response = await _apiService.dio.get(
        '/expenses/',
        queryParameters: {
          'page': _page,
          'category': category,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      final List<dynamic> expenseData = response.data['results'];
      final List<ExpenseModel> fetchedExpenses = expenseData
          .map((json) => ExpenseModel.fromJson(json))
          .toList();

      if (loadMore) {
        expenses.addAll(fetchedExpenses);
      } else {
        expenses.value = fetchedExpenses;
      }

      hasMoreExpenses.value = response.data['next'] != null;
      _page++;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
      expenses.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Create expense
  Future<ExpenseModel?> createExpense(ExpenseModel expense) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.dio.post(
        '/expenses/',
        data: expense.toJson(),
      );

      final createdExpense = ExpenseModel.fromJson(response.data);
      expenses.insert(0, createdExpense);
      return createdExpense;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Update expense
  Future<ExpenseModel?> updateExpense(ExpenseModel expense) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.dio.put(
        '/expenses/${expense.id}/',
        data: expense.toJson(),
      );

      final updatedExpense = ExpenseModel.fromJson(response.data);
      
      // Update in the list
      final index = expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        expenses[index] = updatedExpense;
      }

      return updatedExpense;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  // Delete expense
  Future<bool> deleteExpense(String expenseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      await _apiService.dio.delete('/expenses/$expenseId/');
      
      // Remove from list
      expenses.removeWhere((expense) => expense.id == expenseId);
      
      return true;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Get expense by ID
  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _apiService.dio.get('/expenses/$expenseId/');
      final expense = ExpenseModel.fromJson(response.data);
      
      selectedExpense.value = expense;
      return expense;
    } catch (e) {
      error.value = ErrorHandler.handleError(e);
      return null;
    } finally {
      isLoading.value = false;
    }
  }

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

  @override
  void onInit() {
    super.onInit();
    fetchExpenses();
  }
}