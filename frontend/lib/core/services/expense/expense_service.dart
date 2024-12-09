import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exceptions.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../../data/models/expense/expense_summary_model.dart';

class ExpenseService extends GetxService {
  final ApiClient _apiClient;
  final Logger _logger;
  
  // Observable states
  final RxList<ExpenseModel> expenses = <ExpenseModel>[].obs;
  final Rx<ExpenseSummaryModel?> expenseSummary = Rx<ExpenseSummaryModel?>(null);

  ExpenseService({
    ApiClient? apiClient,
  }) : 
    _apiClient = apiClient ?? Get.find<ApiClient>(),
    _logger = Logger('ExpenseService');

  Future<ExpenseSummaryModel> getExpenseSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.expenseSummary,
        queryParameters: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
        options: Options(
          headers: {'Cache-Control': 'max-age=300'}, // 5 minutes cache
        ),
      );
      return ExpenseSummaryModel.fromJson(response.data);
    } catch (e) {
      _logger.severe('Error fetching expense summary', e);
      throw ApiException('Failed to fetch expense summary');
    }
  }

  // Implement proper error handling with specific error types
  Future<void> validateExpense(ExpenseModel expense) async {
    if (expense.amount <= 0) {
      throw ValidationException('Expense amount must be positive');
    }
    if (expense.date.isAfter(DateTime.now())) {
      throw ValidationException('Expense date cannot be in the future');
    }
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.expenses,
        options: Options(
          headers: {'Cache-Control': 'max-age=300'}, // 5 minutes cache
        ),
      );
      final expensesList = (response.data as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
      expenses.value = expensesList;
      return expensesList;
    } catch (e) {
      _logger.severe('Error fetching expenses', e);
      throw ApiException('Failed to fetch expenses');
    }
  }

  Future<ExpenseModel> createExpense(ExpenseModel expense) async {
    try {
      await validateExpense(expense);
      final response = await _apiClient.dio.post(
        ApiEndpoints.expenses,
        data: expense.toJson(),
      );
      final newExpense = ExpenseModel.fromJson(response.data);
      expenses.add(newExpense);
      return newExpense;
    } catch (e) {
      _logger.severe('Error creating expense', e);
      throw ApiException('Failed to create expense');
    }
  }

  Future<ExpenseModel> updateExpense(String id, ExpenseModel expense) async {
    try {
      await validateExpense(expense);
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.expenses}$id/',
        data: expense.toJson(),
      );
      final updatedExpense = ExpenseModel.fromJson(response.data);
      final index = expenses.indexWhere((e) => e.id == id);
      if (index != -1) {
        expenses[index] = updatedExpense;
      }
      return updatedExpense;
    } catch (e) {
      _logger.severe('Error updating expense', e);
      throw ApiException('Failed to update expense');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.expenses}$id/');
      expenses.removeWhere((e) => e.id == id);
    } catch (e) {
      _logger.severe('Error deleting expense', e);
      throw ApiException('Failed to delete expense');
    }
  }

  Future<List<ExpenseModel>> getRecurringExpenses() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.recurringExpenses,
        options: Options(
          headers: {'Cache-Control': 'max-age=300'}, // 5 minutes cache
        ),
      );
      return (response.data as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching recurring expenses', e);
      throw ApiException('Failed to fetch recurring expenses');
    }
  }

  Future<List<ExpenseModel>> getCategoryExpenses(String category) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.expenseCategories,
        queryParameters: {'category': category},
        options: Options(
          headers: {'Cache-Control': 'max-age=300'}, // 5 minutes cache
        ),
      );
      return (response.data as List)
          .map((json) => ExpenseModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching category expenses', e);
      throw ApiException('Failed to fetch category expenses');
    }
  }

  @override
  void onInit() {
    super.onInit();
    getAllExpenses();
  }
}
