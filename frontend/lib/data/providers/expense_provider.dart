import '../models/expense/expense_model.dart';
import 'api_provider.dart';

class ExpenseProvider {
  final ApiProvider _apiProvider;

  ExpenseProvider(this._apiProvider);

  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? budgetId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      if (category != null) queryParams['category'] = category;
      if (budgetId != null) queryParams['budgetId'] = budgetId;

      final response = await _apiProvider.get('/api/v1/expenses/', queryParameters: queryParams);
      final List<dynamic> expenses = response['data'] ?? [];
      return expenses.map((json) => ExpenseModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<ExpenseModel> getExpense(String id) async {
    final response = await _apiProvider.get('/api/v1/expenses/$id/');
    return ExpenseModel.fromJson(response['data']);
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/api/v1/expenses/', data);
    return ExpenseModel.fromJson(response['data']);
  }

  Future<ExpenseModel> updateExpense(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/api/v1/expenses/$id/', data);
    return ExpenseModel.fromJson(response['data']);
  }

  Future<void> deleteExpense(String id) async {
    await _apiProvider.delete('/api/v1/expenses/$id/');
  }

  Future<Map<String, double>> getExpensesByCategory(DateTime startDate, DateTime endDate) async {
    final response = await _apiProvider.get(
      '/api/v1/expenses/by-category/',
      queryParameters: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    
    final Map<String, dynamic> data = response['data'] ?? {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
}