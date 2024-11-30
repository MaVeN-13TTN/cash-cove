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
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    if (category != null) queryParams['category'] = category;
    if (budgetId != null) queryParams['budgetId'] = budgetId;

    final queryString = queryParams.isEmpty
        ? ''
        : '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final response = await _apiProvider.get('/expenses$queryString');
    return (response['expenses'] as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<ExpenseModel> getExpense(String id) async {
    final response = await _apiProvider.get('/expenses/$id');
    return ExpenseModel.fromJson(response['expense']);
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/expenses', data);
    return ExpenseModel.fromJson(response['expense']);
  }

  Future<ExpenseModel> updateExpense(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/expenses/$id', data);
    return ExpenseModel.fromJson(response['expense']);
  }

  Future<void> deleteExpense(String id) async {
    await _apiProvider.delete('/expenses/$id');
  }

  Future<Map<String, double>> getExpensesByCategory(DateTime startDate, DateTime endDate) async {
    final response = await _apiProvider.get(
      '/expenses/analytics/by-category?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}',
    );
    return Map<String, double>.from(response['categories']);
  }
}