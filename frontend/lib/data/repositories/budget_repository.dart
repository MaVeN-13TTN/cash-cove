import 'package:hive_flutter/hive_flutter.dart';
import '../../core/services/hive_service.dart';
import '../../shared/utils/response_handler.dart';
import '../models/budget/budget_model.dart';
import '../providers/budget_provider.dart';

class BudgetRepository {
  final BudgetProvider _budgetProvider;
  late final Box<BudgetModel> _budgetCache;
  late final Box<Map> _forecastCache;
  late final Box<Map> _utilizationCache;
  
  final _forecastCacheKey = 'budget_forecast';
  final _utilizationCachePrefix = 'budget_utilization_';

  BudgetRepository(this._budgetProvider);

  Future<void> init() async {
    _budgetCache = await HiveService().getBudgetsBox();
    _forecastCache = await Hive.openBox<Map>('budget_forecasts');
    _utilizationCache = await Hive.openBox<Map>('budget_utilizations');
  }

  Future<List<BudgetModel>> getBudgets({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cachedBudgets = _budgetCache.values.toList();
        if (cachedBudgets.isNotEmpty) {
          return cachedBudgets;
        }
      }

      final budgets = await _budgetProvider.getBudgets();
      await _updateCache(budgets);
      
      // Check for empty response
      if (ResponseHandler.isEmptyResponse(budgets)) {
        return [];  // Return empty list to trigger empty state in UI
      }
      
      return budgets;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetModel> getBudget(String id) async {
    try {
      // Check cache first
      final cachedBudget = _budgetCache.get(id);
      if (cachedBudget != null) {
        return cachedBudget;
      }

      final budget = await _budgetProvider.getBudget(id);
      await _budgetCache.put(id, budget);
      return budget;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    try {
      final budget = await _budgetProvider.createBudget(data);
      await _budgetCache.put(budget.id, budget);
      return budget;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    try {
      final budget = await _budgetProvider.updateBudget(id, data);
      await _budgetCache.put(id, budget);
      return budget;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _budgetProvider.deleteBudget(id);
      await _budgetCache.delete(id);
      // Clean up utilization cache for this budget
      await _utilizationCache.delete('$_utilizationCachePrefix$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<BudgetModel>> getBudgetsByCategory(String category) async {
    try {
      final budgets = await _budgetProvider.getBudgetsByCategory(category);
      // Update cache for each budget
      for (var budget in budgets) {
        await _budgetCache.put(budget.id, budget);
      }
      return budgets;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBudgetForecast() async {
    try {
      // Check cache first
      final cachedForecast = _forecastCache.get(_forecastCacheKey);
      if (cachedForecast != null) {
        return Map<String, dynamic>.from(cachedForecast);
      }

      final forecast = await _budgetProvider.getBudgetForecast();
      await _forecastCache.put(_forecastCacheKey, forecast);
      return forecast;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getBudgetUtilization(String budgetId) async {
    try {
      // Check cache first
      final cacheKey = '$_utilizationCachePrefix$budgetId';
      final cachedUtilization = _utilizationCache.get(cacheKey);
      if (cachedUtilization != null) {
        return Map<String, dynamic>.from(cachedUtilization);
      }

      final utilization = await _budgetProvider.getBudgetUtilization(budgetId);
      await _utilizationCache.put(cacheKey, utilization);
      return utilization;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> _updateCache(List<BudgetModel> budgets) async {
    await _budgetCache.clear();
    for (var budget in budgets) {
      await _budgetCache.put(budget.id, budget);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is Exception) {
      return error;
    }
    return Exception('An unexpected error occurred: $error');
  }
}