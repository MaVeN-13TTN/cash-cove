import 'package:get/get.dart';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exceptions.dart';
import '../../../data/models/budget/budget_model.dart';

class BudgetService extends GetxService {
  final ApiClient _apiClient;
  final Logger _logger;
  
  // Observable states
  final RxList<BudgetModel> budgets = <BudgetModel>[].obs;
  final Rx<BudgetModel?> selectedBudget = Rx<BudgetModel?>(null);

  BudgetService({
    ApiClient? apiClient,
  }) : 
    _apiClient = apiClient ?? Get.find<ApiClient>(),
    _logger = Logger('BudgetService');

  Future<List<BudgetModel>> getActiveBudgets() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.activeBudgets,
        options: Options(
          headers: {'Cache-Control': 'max-age=300'}, // 5 minutes cache
        ),
      );
      return (response.data as List)
          .map((json) => BudgetModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching active budgets', e);
      throw ApiException('Failed to fetch active budgets');
    }
  }

  Future<BudgetModel> copyBudget(String budgetId) async {
    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.copyBudget.replaceAll('{id}', budgetId),
      );
      return BudgetModel.fromJson(response.data);
    } catch (e) {
      _logger.severe('Error copying budget', e);
      throw ApiException('Failed to copy budget');
    }
  }

  Future<List<BudgetModel>> getAllBudgets() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.budgets,
        options: Options(
          headers: {'Cache-Control': 'max-age=300'}, // 5 minutes cache
        ),
      );
      final budgetsList = (response.data as List)
          .map((json) => BudgetModel.fromJson(json))
          .toList();
      budgets.value = budgetsList;
      return budgetsList;
    } catch (e) {
      _logger.severe('Error fetching budgets', e);
      throw ApiException('Failed to fetch budgets');
    }
  }

  Future<BudgetModel> createBudget(BudgetModel budget) async {
    try {
      await validateBudget(budget);
      final response = await _apiClient.dio.post(
        ApiEndpoints.budgets,
        data: budget.toJson(),
      );
      final newBudget = BudgetModel.fromJson(response.data);
      budgets.add(newBudget);
      return newBudget;
    } catch (e) {
      _logger.severe('Error creating budget', e);
      throw ApiException('Failed to create budget');
    }
  }

  Future<BudgetModel> updateBudget(String id, BudgetModel budget) async {
    try {
      await validateBudget(budget);
      final response = await _apiClient.dio.put(
        '${ApiEndpoints.budgets}$id/',
        data: budget.toJson(),
      );
      final updatedBudget = BudgetModel.fromJson(response.data);
      final index = budgets.indexWhere((b) => b.id == id);
      if (index != -1) {
        budgets[index] = updatedBudget;
      }
      return updatedBudget;
    } catch (e) {
      _logger.severe('Error updating budget', e);
      throw ApiException('Failed to update budget');
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _apiClient.dio.delete('${ApiEndpoints.budgets}$id/');
      budgets.removeWhere((b) => b.id == id);
    } catch (e) {
      _logger.severe('Error deleting budget', e);
      throw ApiException('Failed to delete budget');
    }
  }

  Future<List<BudgetModel>> getCategoryBudgets(String category) async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.budgetCategories,
        queryParameters: {'category': category},
        options: Options(
          headers: {'Cache-Control': 'max-age=300'}, // 5 minutes cache
        ),
      );
      return (response.data as List)
          .map((json) => BudgetModel.fromJson(json))
          .toList();
    } catch (e) {
      _logger.severe('Error fetching category budgets', e);
      throw ApiException('Failed to fetch category budgets');
    }
  }

  // Implement proper error handling with specific error types
  Future<void> validateBudget(BudgetModel budget) async {
    if (budget.amount < 0) {
      throw ValidationException('Budget amount cannot be negative');
    }
    if (budget.startDate.isAfter(budget.endDate)) {
      throw ValidationException('Start date cannot be after end date');
    }
  }

  @override
  void onInit() {
    super.onInit();
    getAllBudgets();
  }
}
