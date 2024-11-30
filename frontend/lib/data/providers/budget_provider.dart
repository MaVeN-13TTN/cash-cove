import '../models/budget/budget_model.dart';
import 'api_provider.dart';

class BudgetProvider {
  final ApiProvider _apiProvider;

  BudgetProvider(this._apiProvider);

  Future<List<BudgetModel>> getBudgets() async {
    final response = await _apiProvider.get('/budgets');
    return (response['budgets'] as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }

  Future<BudgetModel> getBudget(String id) async {
    final response = await _apiProvider.get('/budgets/$id');
    return BudgetModel.fromJson(response['budget']);
  }

  Future<BudgetModel> createBudget(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/budgets', data);
    return BudgetModel.fromJson(response['budget']);
  }

  Future<BudgetModel> updateBudget(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/budgets/$id', data);
    return BudgetModel.fromJson(response['budget']);
  }

  Future<void> deleteBudget(String id) async {
    await _apiProvider.delete('/budgets/$id');
  }

  Future<List<BudgetModel>> getBudgetsByCategory(String category) async {
    final response = await _apiProvider.get('/budgets/category/$category');
    return (response['budgets'] as List)
        .map((json) => BudgetModel.fromJson(json))
        .toList();
  }
}