import '../models/budget/budget_model.dart';
import '../models/user/user_model.dart';
import 'api_provider.dart';

class BudgetProvider {
  final ApiProvider _apiProvider;

  BudgetProvider(this._apiProvider);

  Future<List<BudgetModel>> getBudgets() async {
    try {
      final response = await _apiProvider.get('/budgets/');
      final List<dynamic> budgets = response['data'] ?? [];
      return budgets.map((json) => BudgetModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<BudgetModel> getBudget(String id) async {
    final response = await _apiProvider.get('/budgets/$id/');
    return BudgetModel.fromJson(response['data']);
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/budgets/', data);
    return BudgetModel.fromJson(response['data']);
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/budgets/$id/', data);
    return BudgetModel.fromJson(response['data']);
  }

  Future<void> deleteBudget(String id) async {
    await _apiProvider.delete('/budgets/$id/');
  }

  Future<List<BudgetModel>> getBudgetsByCategory(String category) async {
    try {
      final response = await _apiProvider.get(
        '/budgets/by-category/',
        queryParameters: {'category': category},
      );
      final List<dynamic> budgets = response['data'] ?? [];
      return budgets.map((json) => BudgetModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  // New Analytics Methods
  Future<Map<String, dynamic>> getBudgetAnalytics(String budgetId) async {
    final response = await _apiProvider.get('/budgets/$budgetId/analytics/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getBudgetPerformance(String budgetId) async {
    final response = await _apiProvider.get('/budgets/$budgetId/performance/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getBudgetProjections(String budgetId) async {
    final response = await _apiProvider.get('/budgets/$budgetId/projections/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  // Budget Sharing
  Future<void> shareBudget(String budgetId, List<String> userIds) async {
    await _apiProvider.post(
      '/budgets/$budgetId/share/',
      {'user_ids': userIds},
    );
  }

  Future<void> removeBudgetShare(String budgetId, String userId) async {
    await _apiProvider.delete('/budgets/$budgetId/share/$userId/');
  }

  Future<List<UserModel>> getBudgetShares(String budgetId) async {
    final response = await _apiProvider.get('/budgets/$budgetId/shares/');
    return (response['data'] as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  // Budget Categories
  Future<List<String>> getAvailableCategories() async {
    final response = await _apiProvider.get('/budgets/categories/');
    return List<String>.from(response['data'] ?? []);
  }

  Future<Map<String, dynamic>> getCategorySpendingLimits() async {
    final response = await _apiProvider.get('/budgets/category-limits/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<void> setCategoryLimit(String category, double limit) async {
    await _apiProvider.post(
      '/budgets/category-limits/',
      {'category': category, 'limit': limit},
    );
  }

  // Budget Rules
  Future<void> addBudgetRule(String budgetId, Map<String, dynamic> rule) async {
    await _apiProvider.post('/budgets/$budgetId/rules/', rule);
  }

  Future<void> removeBudgetRule(String budgetId, String ruleId) async {
    await _apiProvider.delete('/budgets/$budgetId/rules/$ruleId/');
  }

  Future<List<Map<String, dynamic>>> getBudgetRules(String budgetId) async {
    final response = await _apiProvider.get('/budgets/$budgetId/rules/');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  // Budget Notifications
  Future<void> setBudgetAlert(String budgetId, Map<String, dynamic> alert) async {
    await _apiProvider.post('/budgets/$budgetId/alerts/', alert);
  }

  Future<void> removeBudgetAlert(String budgetId, String alertId) async {
    await _apiProvider.delete('/budgets/$budgetId/alerts/$alertId/');
  }

  Future<List<Map<String, dynamic>>> getBudgetAlerts(String budgetId) async {
    final response = await _apiProvider.get('/budgets/$budgetId/alerts/');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }
}