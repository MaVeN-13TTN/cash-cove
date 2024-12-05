import '../models/budget/budget_model.dart';
import 'api_provider.dart';

class BudgetProvider {
  final ApiProvider _apiProvider;

  BudgetProvider(this._apiProvider);

  Future<List<BudgetModel>> getBudgets() async {
    try {
      final response = await _apiProvider.get('/api/v1/budgets/');
      final List<dynamic> budgets = response['data'] ?? [];
      return budgets.map((json) => BudgetModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<BudgetModel> getBudget(String id) async {
    final response = await _apiProvider.get('/api/v1/budgets/$id/');
    return BudgetModel.fromJson(response['data']);
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/api/v1/budgets/', data);
    return BudgetModel.fromJson(response['data']);
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/api/v1/budgets/$id/', data);
    return BudgetModel.fromJson(response['data']);
  }

  Future<void> deleteBudget(String id) async {
    await _apiProvider.delete('/api/v1/budgets/$id/');
  }

  Future<List<BudgetModel>> getBudgetsByCategory(String category) async {
    try {
      final response = await _apiProvider.get(
        '/api/v1/budgets/by-category/',
        queryParameters: {'category': category},
      );
      final List<dynamic> budgets = response['data'] ?? [];
      return budgets.map((json) => BudgetModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }
}