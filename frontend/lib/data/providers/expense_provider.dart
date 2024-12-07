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
      };

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
      '/api/v1/expenses/category_distribution/',
      queryParameters: {
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
      },
    );
    
    final Map<String, dynamic> data = response['data'] ?? {};
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  Future<List<Map<String, dynamic>>> getMonthlyTrend({
    int months = 12,
    String? category,
  }) async {
    final response = await _apiProvider.get(
      '/api/v1/expenses/monthly_trend/',
      queryParameters: {
        'months': months.toString(),
        if (category != null) 'category': category,
      },
    );
    return List<Map<String, dynamic>>.from(response['data'] ?? []);
  }

  Future<List<ExpenseModel>> createRecurringExpense({
    required Map<String, dynamic> expenseData,
    required DateTime startDate,
    required DateTime endDate,
    required String frequency,
  }) async {
    final response = await _apiProvider.post(
      '/api/v1/expenses/create_recurring/',
      {
        'expense_data': expenseData,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'frequency': frequency,
      },
    );
    return (response['data'] as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<List<ExpenseModel>> getRecurringExpenseForecast({int months = 3}) async {
    final response = await _apiProvider.get(
      '/api/v1/expenses/forecast/',
      queryParameters: {'months': months.toString()},
    );
    return (response['data'] as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  Future<ExpenseModel> attachToBudget(String expenseId, String budgetId) async {
    final response = await _apiProvider.post(
      '/api/v1/expenses/$expenseId/attach_to_budget/',
      {'budget_id': budgetId},
    );
    return ExpenseModel.fromJson(response['data']);
  }

  Future<ExpenseModel> duplicateExpense(String expenseId) async {
    final response = await _apiProvider.post(
      '/api/v1/expenses/$expenseId/duplicate/',
      {},
    );
    return ExpenseModel.fromJson(response['data']);
  }

  Future<Map<String, dynamic>> getExpenseInsights() async {
    final response = await _apiProvider.get('/api/v1/expenses/insights/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  // New Methods for Tags
  Future<void> addTags(String expenseId, List<String> tags) async {
    await _apiProvider.post(
      '/api/v1/expenses/$expenseId/tags/',
      {'tags': tags},
    );
  }

  Future<void> removeTags(String expenseId, List<String> tags) async {
    await _apiProvider.delete(
      '/api/v1/expenses/$expenseId/tags/',
      data: {'tags': tags},
    );
  }

  Future<List<String>> getTags(String expenseId) async {
    final response = await _apiProvider.get('/api/v1/expenses/$expenseId/tags/');
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
    await _apiProvider.post(
      '/api/v1/expenses/$expenseId/attachments/',
      formData,
    );
  }

  Future<void> removeAttachment(String expenseId, String attachmentId) async {
    await _apiProvider.delete(
      '/api/v1/expenses/$expenseId/attachments/$attachmentId/',
    );
  }

  Future<List<String>> getAttachments(String expenseId) async {
    final response = await _apiProvider.get(
      '/api/v1/expenses/$expenseId/attachments/',
    );
    return List<String>.from(response['data'] ?? []);
  }

  // Search
  Future<List<ExpenseModel>> searchExpenses(String query) async {
    final response = await _apiProvider.get(
      '/api/v1/expenses/search/',
      queryParameters: {'q': query},
    );
    return (response['data'] as List)
        .map((json) => ExpenseModel.fromJson(json))
        .toList();
  }

  // Advanced Analytics
  Future<Map<String, dynamic>> getExpensePatterns() async {
    final response = await _apiProvider.get('/api/v1/expenses/patterns/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }

  Future<Map<String, dynamic>> getPredictedExpenses() async {
    final response = await _apiProvider.get('/api/v1/expenses/predictions/');
    return Map<String, dynamic>.from(response['data'] ?? {});
  }
}