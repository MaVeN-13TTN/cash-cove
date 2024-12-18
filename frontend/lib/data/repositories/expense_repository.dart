import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense/expense_model.dart';
import '../providers/expense_provider.dart';
import '../../core/services/hive_service.dart';
import '../../shared/utils/response_handler.dart';

class ExpenseRepository {
  final ExpenseProvider _expenseProvider;
  late Box<ExpenseModel> _localCache;

  ExpenseRepository(this._expenseProvider) {
    _initializeBox();
  }

  Future<void> _initializeBox() async {
    final hiveService = HiveService();
    _localCache = await hiveService.getExpensesBox();
  }

  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? budgetId,
    bool forceRefresh = false,
    int page = 1,
    int? limit,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedExpenses = _localCache.values.toList();
        var filteredExpenses = _filterCachedExpenses(
          cachedExpenses,
          startDate: startDate,
          endDate: endDate,
          category: category,
          budgetId: budgetId,
        );

        // Apply pagination to cached expenses
        if (limit != null) {
          final startIndex = (page - 1) * limit;
          final endIndex = startIndex + limit;
          filteredExpenses = filteredExpenses.sublist(
            startIndex, 
            endIndex > filteredExpenses.length ? filteredExpenses.length : endIndex
          );
        }

        if (filteredExpenses.isNotEmpty) {
          return filteredExpenses;
        }
      }

      final expenses = await _expenseProvider.getExpenses(
        startDate: startDate,
        endDate: endDate,
        category: category,
        budgetId: budgetId,
        page: page,
        limit: limit,
      );

      // Check for empty response
      if (ResponseHandler.isEmptyResponse(expenses)) {
        return [];  // Return empty list to trigger empty state in UI
      }

      await _updateCache(expenses);
      return expenses;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ExpenseModel> getExpense(String id) async {
    try {
      final cachedExpense = _localCache.get(id);
      if (cachedExpense != null) {
        return cachedExpense;
      }

      final expense = await _expenseProvider.getExpense(id);
      await _localCache.put(id, expense);
      return expense;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> data) async {
    try {
      final expense = await _expenseProvider.createExpense(data);
      await _localCache.put(expense.id, expense);
      return expense;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ExpenseModel> updateExpense(String id, Map<String, dynamic> data) async {
    try {
      final expense = await _expenseProvider.updateExpense(id, data);
      await _localCache.put(id, expense);
      return expense;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _expenseProvider.deleteExpense(id);
      await _localCache.delete(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, double>> getExpensesByCategory(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _expenseProvider.getExpensesByCategory(startDate, endDate);
    } catch (e) {
      throw _handleError(e);
    }
  }

  List<ExpenseModel> _filterCachedExpenses(
    List<ExpenseModel> expenses, {
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? budgetId,
  }) {
    return expenses.where((expense) {
      if (startDate != null && expense.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && expense.date.isAfter(endDate)) {
        return false;
      }
      if (category != null && expense.category != category) {
        return false;
      }
      if (budgetId != null && expense.budgetId != budgetId) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _updateCache(List<ExpenseModel> expenses) async {
    await _localCache.clear();
    for (var expense in expenses) {
      await _localCache.put(expense.id, expense);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception('An unexpected error occurred: $error');
  }
}