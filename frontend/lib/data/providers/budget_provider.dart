import 'package:budget_tracker/core/utils/logger_utils.dart';
import 'package:budget_tracker/data/models/budget/budget_model.dart';
import 'package:budget_tracker/data/models/user/user_model.dart';
import 'api_provider.dart';

class BudgetProvider {
  final ApiProvider _apiProvider;
  static const _endpoint = '/budgets/';  // Base endpoint for budgets

  BudgetProvider(this._apiProvider);

  Future<List<BudgetModel>> getBudgets() async {
    try {
      LoggerUtils.info('Fetching budgets');
      final response = await _apiProvider.get(_endpoint);
      final List<dynamic> budgets = response['data'] ?? [];
      return budgets.map((json) => BudgetModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      LoggerUtils.warning('Failed to fetch budgets', e);
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<BudgetModel> getBudget(String id) async {
    final response = await _apiProvider.get('$_endpoint$id/');
    final data = response is Map ? response['data'] ?? response : response;
    return BudgetModel.fromJson(data);
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    try {
      LoggerUtils.info('Creating new budget');
      // Convert to snake_case for backend
      final requestData = _prepareRequestData(data);
      
      final response = await _apiProvider.post(_endpoint, requestData);
      return BudgetModel.fromJson(response['data']);
    } catch (e) {
      LoggerUtils.error('Failed to create budget', e);
      rethrow;
    }
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    try {
      LoggerUtils.info('Updating budget: $id');
      final requestData = _prepareRequestData(data);
      
      final response = await _apiProvider.put('$_endpoint$id/', requestData);
      return BudgetModel.fromJson(response['data']);
    } catch (e) {
      LoggerUtils.error('Failed to update budget: $id', e);
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      LoggerUtils.info('Deleting budget: $id');
      await _apiProvider.delete('$_endpoint$id/');
    } catch (e) {
      LoggerUtils.error('Failed to delete budget: $id', e);
      rethrow;
    }
  }

  Future<List<BudgetModel>> getBudgetsByCategory(String category) async {
    try {
      final response = await _apiProvider.get('/budgets/by-category/');
      final List<dynamic> budgets = response['data'] ?? [];
      return budgets.map((json) => BudgetModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  // New Analytics Methods
  Future<Map<String, dynamic>> getBudgetAnalytics(String budgetId) async {
    final response = await _apiProvider.get('$_endpoint$budgetId/analytics/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getBudgetPerformance(String budgetId) async {
    final response = await _apiProvider.get('$_endpoint$budgetId/performance/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getBudgetProjections(String budgetId) async {
    final response = await _apiProvider.get('$_endpoint$budgetId/projections/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getBudgetForecast() async {
    try {
      LoggerUtils.info('Fetching budget forecast');
      final response = await _apiProvider.get('/budgets/forecast/');
      return Map<String, dynamic>.from(response['data'] ?? {});
    } catch (e) {
      LoggerUtils.error('Failed to fetch budget forecast', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBudgetUtilization(String budgetId) async {
    try {
      LoggerUtils.info('Fetching budget utilization for: $budgetId');
      final response = await _apiProvider.get('$_endpoint$budgetId/utilization/');
      return Map<String, dynamic>.from(response['data'] ?? {});
    } catch (e) {
      LoggerUtils.error('Failed to fetch budget utilization', e);
      rethrow;
    }
  }

  // Budget Sharing
  Future<void> shareBudget(String budgetId, List<String> userIds) async {
    await _apiProvider.post(
      '$_endpoint$budgetId/share/',
      {'user_ids': userIds},
    );
  }

  Future<void> removeBudgetShare(String budgetId, String userId) async {
    await _apiProvider.delete('$_endpoint$budgetId/share/$userId/');
  }

  Future<List<UserModel>> getBudgetShares(String budgetId) async {
    final response = await _apiProvider.get('$_endpoint$budgetId/shares/');
    return (response['data'] as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  // Budget Categories
  Future<List<String>> getAvailableCategories() async {
    final response = await _apiProvider.get('/budgets/categories/');
    return List<String>.from(response['data'] ?? []);
  }

  Map<String, dynamic> _prepareRequestData(Map<String, dynamic> data) {
    // Convert camelCase to snake_case for backend compatibility
    return {
      'name': data['name'],
      'amount': data['amount'],
      'category': data['category'],
      'start_date': data['startDate'],
      'end_date': data['endDate'],
      'description': data['description'],
      if (data.containsKey('isRecurring')) 'is_recurring': data['isRecurring'],
      if (data.containsKey('recurringPeriod')) 'recurring_period': data['recurringPeriod'],
    };
  }
}