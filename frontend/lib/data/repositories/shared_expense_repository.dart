import 'package:hive_flutter/hive_flutter.dart';
import '../models/shared_expense/shared_expense_model.dart';
import '../providers/shared_expense_provider.dart';

class SharedExpenseRepository {
  final SharedExpenseProvider _sharedExpenseProvider;
  final Box<SharedExpenseModel> _localCache;
  static const String _cacheBoxName = 'shared_expenses';

  SharedExpenseRepository(this._sharedExpenseProvider)
      : _localCache = Hive.box<SharedExpenseModel>(_cacheBoxName);

  Future<List<SharedExpenseModel>> getSharedExpenses({
    String? groupId,
    DateTime? startDate,
    DateTime? endDate,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedExpenses = _localCache.values.toList();
        if (cachedExpenses.isNotEmpty) {
          return _filterCachedExpenses(
            cachedExpenses,
            groupId: groupId,
            startDate: startDate,
            endDate: endDate,
          );
        }
      }

      final expenses = await _sharedExpenseProvider.getSharedExpenses(
        groupId: groupId,
        startDate: startDate,
        endDate: endDate,
      );
      await _updateCache(expenses);
      return expenses;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SharedExpenseModel> getSharedExpense(String id) async {
    try {
      final cachedExpense = _localCache.get(id);
      if (cachedExpense != null) {
        return cachedExpense;
      }

      final expense = await _sharedExpenseProvider.getSharedExpense(id);
      await _localCache.put(id, expense);
      return expense;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SharedExpenseModel> createSharedExpense(Map<String, dynamic> data) async {
    try {
      final expense = await _sharedExpenseProvider.createSharedExpense(data);
      await _localCache.put(expense.id, expense);
      return expense;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SharedExpenseModel> updateSharedExpense(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final expense = await _sharedExpenseProvider.updateSharedExpense(id, data);
      await _localCache.put(id, expense);
      return expense;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteSharedExpense(String id) async {
    try {
      await _sharedExpenseProvider.deleteSharedExpense(id);
      await _localCache.delete(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, double>> calculateShares(String expenseId) async {
    try {
      return await _sharedExpenseProvider.calculateShares(expenseId);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> settleExpense(String expenseId, String userId) async {
    try {
      await _sharedExpenseProvider.settleExpense(expenseId, userId);
      // Update the cached expense to reflect settlement
      final expense = await getSharedExpense(expenseId);
      await _localCache.put(expenseId, expense);
    } catch (e) {
      throw _handleError(e);
    }
  }

  List<SharedExpenseModel> _filterCachedExpenses(
    List<SharedExpenseModel> expenses, {
    String? groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return expenses.where((expense) {
      if (groupId != null && expense.groupId != groupId) {
        return false;
      }
      if (startDate != null && expense.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && expense.date.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  Future<void> _updateCache(List<SharedExpenseModel> expenses) async {
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