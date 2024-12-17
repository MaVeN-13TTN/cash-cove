import 'dart:io';
import 'package:dio/dio.dart';
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
    bool? isRecurring,
    double? minAmount,
    double? maxAmount,
    List<String>? tags,
    int page = 1,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (category != null) 'category': category,
        if (budgetId != null) 'budget_id': budgetId,
        if (isRecurring != null) 'is_recurring': isRecurring.toString(),
        if (minAmount != null) 'min_amount': minAmount.toString(),
        if (maxAmount != null) 'max_amount': maxAmount.toString(),
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
        if (limit != null) 'limit': limit.toString(),
      };

      final response = await _apiProvider.get('/expenses/?${Uri(queryParameters: queryParams).query}');
      final List<dynamic> expenses = response['data'] ?? [];
      return expenses.map((json) => ExpenseModel.fromJson(json)).toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) return [];
      rethrow;
    }
  }

  Future<ExpenseModel> getExpense(String id) async {
    final response = await _apiProvider.get('/expenses/$id/');
    return ExpenseModel.fromJson(response['data']);
  }

  Future<ExpenseModel> createExpense(Map<String, dynamic> expenseData) async {
    final response = await _apiProvider.post('/expenses/', expenseData);
    return ExpenseModel.fromJson(response['data']);
  }

  Future<ExpenseModel> updateExpense(String id, Map<String, dynamic> expenseData) async {
    final response = await _apiProvider.put('/expenses/$id/', expenseData);
    return ExpenseModel.fromJson(response['data']);
  }

  Future<void> deleteExpense(String id) async {
    await _apiProvider.delete('/expenses/$id/');
  }

  Future<Map<String, double>> getExpensesByCategory(DateTime startDate, DateTime endDate) async {
    final queryParams = {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
    final response = await _apiProvider.get('/expenses/category_distribution/?${Uri(queryParameters: queryParams).query}');
    final Map<String, dynamic> data = response['data'] ?? {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrend({
    int months = 12,
    String? category,
  }) async {
    final queryParams = {
      'months': months.toString(),
      if (category != null) 'category': category,
    };
    final response = await _apiProvider.get('/expenses/monthly_trend/?${Uri(queryParameters: queryParams).query}');
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  Future<List<ExpenseModel>> createRecurringExpense({
    required Map<String, dynamic> expenseData,
    required DateTime startDate,
    required DateTime endDate,
    required String frequency,
  }) async {
    final queryParams = {
      'expense_data': expenseData,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'frequency': frequency,
    };
    final response = await _apiProvider.post('/expenses/create_recurring/', queryParams);
    return (response['data'] as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<List<ExpenseModel>> getRecurringExpenseForecast({int months = 3}) async {
    final queryParams = {'months': months.toString()};
    final response = await _apiProvider.get('/expenses/forecast/?${Uri(queryParameters: queryParams).query}');
    return (response['data'] as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<ExpenseModel> attachToBudget(String expenseId, String budgetId) async {
    final response = await _apiProvider.post('/expenses/$expenseId/attach_to_budget/', {'budget_id': budgetId});
    return ExpenseModel.fromJson(response['data']);
  }

  Future<ExpenseModel> duplicateExpense(String expenseId) async {
    final response = await _apiProvider.post('/expenses/$expenseId/duplicate/', {});
    return ExpenseModel.fromJson(response['data']);
  }

  Future<Map<String, dynamic>> getExpenseInsights() async {
    final response = await _apiProvider.get('/expenses/insights/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  // New Methods for Tags
  Future<void> addTags(String expenseId, List<String> tags) async {
    final queryParams = {'tags': tags};
    await _apiProvider.post('/expenses/$expenseId/tags/', queryParams);
  }

  Future<void> removeTags(String expenseId, List<String> tags) async {
    await _apiProvider.delete('/expenses/$expenseId/tags/');
  }

  Future<List<String>> getTags(String expenseId) async {
    final response = await _apiProvider.get('/expenses/$expenseId/tags/');
    return List<String>.from(response['data'] ?? []);
  }

  // Attachments
  Future<void> addAttachment(String expenseId, File attachment) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        attachment.path,
        filename: attachment.path.split('/').last,
      ),
    });
    await _apiProvider.post('/expenses/$expenseId/attachments/', formData);
  }

  Future<void> removeAttachment(String expenseId, String attachmentId) async {
    await _apiProvider.delete('/expenses/$expenseId/attachments/$attachmentId/');
  }

  Future<List<String>> getAttachments(String expenseId) async {
    final response = await _apiProvider.get('/expenses/$expenseId/attachments/');
    return List<String>.from(response['data'] ?? []);
  }

  // Search
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    final queryParams = {'q': query};
    final response = await _apiProvider.get('/expenses/search/?${Uri(queryParameters: queryParams).query}');
    return (response['data'] as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  // Advanced Analytics
  Future<Map<String, dynamic>> getExpensePatterns() async {
    final response = await _apiProvider.get('/expenses/patterns/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getPredictedExpenses() async {
    final response = await _apiProvider.get('/expenses/predictions/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }
}