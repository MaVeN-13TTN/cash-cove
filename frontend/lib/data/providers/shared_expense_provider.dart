import '../models/shared_expense/shared_expense_model.dart';
import '../models/group/group_model.dart';
import '../models/user/user_model.dart';
import '../models/settlement/settlement_model.dart';
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

  Future<List<GroupModel>> getGroups() async {
    final response = await _apiProvider.get('/groups');
    return (response['groups'] as List)
        .map((json) => GroupModel.fromJson(json))
        .toList();
  }

  Future<GroupModel> createGroup(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/groups', data);
    return GroupModel.fromJson(response['group']);
  }

  Future<GroupModel> updateGroup(String id, Map<String, dynamic> data) async {
    final response = await _apiProvider.put('/groups/$id', data);
    return GroupModel.fromJson(response['group']);
  }

  Future<void> deleteGroup(String id) async {
    await _apiProvider.delete('/groups/$id');
  }

  Future<void> addMember(String groupId, String userId) async {
    await _apiProvider.post('/groups/$groupId/members', {'userId': userId});
  }

  Future<void> removeMember(String groupId, String userId) async {
    await _apiProvider.delete('/groups/$groupId/members/$userId');
  }

  Future<List<UserModel>> getGroupMembers(String groupId) async {
    final response = await _apiProvider.get('/groups/$groupId/members');
    return (response['members'] as List)
        .map((json) => UserModel.fromJson(json))
        .toList();
  }

  Future<List<SettlementModel>> getSettlements(String groupId) async {
    final response = await _apiProvider.get('/groups/$groupId/settlements');
    return (response['settlements'] as List)
        .map((json) => SettlementModel.fromJson(json))
        .toList();
  }

  Future<SettlementModel> createSettlement(Map<String, dynamic> data) async {
    final response = await _apiProvider.post('/settlements', data);
    return SettlementModel.fromJson(response['settlement']);
  }

  Future<void> markSettlementPaid(String settlementId) async {
    await _apiProvider.put('/settlements/$settlementId/mark-paid', {});
  }

  Future<Map<String, dynamic>> getGroupAnalytics(String groupId) async {
    final response = await _apiProvider.get('/groups/$groupId/analytics');
    return Map<String, dynamic>.from(response['analytics']);
  }

  Future<Map<String, dynamic>> getMemberContributions(String groupId) async {
    final response = await _apiProvider.get('/groups/$groupId/contributions');
    return Map<String, dynamic>.from(response['contributions']);
  }
}