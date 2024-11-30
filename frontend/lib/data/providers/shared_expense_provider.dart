import '../models/shared_expense/shared_expense_model.dart';
import 'api_provider.dart';

class SharedExpenseProvider {
  final ApiProvider _apiProvider;

  SharedExpenseProvider(this._apiProvider);

  Future<List<SharedExpenseModel>> getSharedExpenses({
    String? groupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final queryParams = <String, String>{};
    if (groupId != null) queryParams['groupId'] = groupId;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();

    final response = await _apiProvider.get(
      '/shared-expenses',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return (response['sharedExpenses'] as List)
        .map((json) => SharedExpenseModel.fromJson(json))
        .toList();
  }

  Future<SharedExpenseModel> getSharedExpense(String id) async {
    final response = await _apiProvider.get('/shared-expenses/$id');
    return SharedExpenseModel.fromJson(response['sharedExpense']);
  }

  Future<SharedExpenseModel> createSharedExpense(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/shared-expenses', data);
    return SharedExpenseModel.fromJson(response['sharedExpense']);
  }

  Future<SharedExpenseModel> updateSharedExpense(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/shared-expenses/$id', data);
    return SharedExpenseModel.fromJson(response['sharedExpense']);
  }

  Future<void> deleteSharedExpense(String id) async {
    await _apiProvider.delete('/shared-expenses/$id');
  }

  Future<Map<String, double>> calculateShares(String expenseId) async {
    final response = await _apiProvider.get('/shared-expenses/$expenseId/shares');
    return Map<String, double>.from(response['shares']);
  }

  Future<void> settleExpense(String expenseId, String userId) async {
    await _apiProvider.post('/shared-expenses/$expenseId/settle', {
      'userId': userId,
    });
  }

  Future<List<SharedExpenseModel>> getPendingSharedExpenses() async {
    final response = await _apiProvider.get('/shared-expenses/pending');
    return (response['sharedExpenses'] as List)
        .map((json) => SharedExpenseModel.fromJson(json))
        .toList();
  }
}