import 'package:hive_flutter/hive_flutter.dart';
import '../models/budget/budget_model.dart';
import '../providers/budget_provider.dart';

class BudgetRepository {
  final BudgetProvider _budgetProvider;
  final Box<BudgetModel> _localCache;
  static const String _cacheBoxName = 'budgets';

  BudgetRepository(this._budgetProvider) : _localCache = Hive.box<BudgetModel>(_cacheBoxName);

  Future<List<BudgetModel>> getBudgets({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedBudgets = _localCache.values.toList();
        if (cachedBudgets.isNotEmpty) {
          return cachedBudgets;
        }
      }

      final budgets = await _budgetProvider.getBudgets();
      await _updateCache(budgets);
      return budgets;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetModel> getBudget(String id) async {
    try {
      // Check cache first
      final cachedBudget = _localCache.get(id);
      if (cachedBudget != null) {
        return cachedBudget;
      }

      final budget = await _budgetProvider.getBudget(id);
      await _localCache.put(id, budget);
      return budget;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    try {
      final budget = await _budgetProvider.createBudget(data);
      await _localCache.put(budget.id, budget);
      return budget;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    try {
      final budget = await _budgetProvider.updateBudget(id, data);
      await _localCache.put(id, budget);
      return budget;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _budgetProvider.deleteBudget(id);
      await _localCache.delete(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BudgetModel>> getBudgetsByCategory(String category) async {
    try {
      final budgets = await _budgetProvider.getBudgetsByCategory(category);
      // Update cache for each budget
      for (var budget in budgets) {
        await _localCache.put(budget.id, budget);
      }
      return budgets;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> _updateCache(List<BudgetModel> budgets) async {
    await _localCache.clear();
    for (var budget in budgets) {
      await _localCache.put(budget.id, budget);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception('An unexpected error occurred: $error');
  }
}