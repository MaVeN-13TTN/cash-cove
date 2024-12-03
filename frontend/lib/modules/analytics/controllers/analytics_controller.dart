import 'package:get/get.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../data/models/budget/budget_model.dart';
import '../../../core/services/api/api_client.dart';
import '../../../core/utils/logger_utils.dart';

class AnalyticsController extends GetxController {
  final ApiClient _apiClient = Get.find<ApiClient>();

  // Reactive variables for analytics data
  final RxList<ExpenseModel> _expenses = <ExpenseModel>[].obs;
  final RxList<BudgetModel> _budgets = <BudgetModel>[].obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble totalIncome = 0.0.obs;
  final RxMap<String, double> categorySpending = <String, double>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnalytics();
  }

  // Refresh analytics data (for use in tab switching)
  Future<void> refreshAnalytics() async {
    await fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      isLoading.value = true;
      error.value = '';

      // Fetch expenses and budgets
      await Future.wait([
        fetchExpenses(),
        fetchBudgets(),
      ]);

      calculateAnalytics();
    } catch (e, stackTrace) {
      error.value = 'Failed to fetch analytics data';
      LoggerUtils.error('Error fetching analytics', e, stackTrace);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchExpenses() async {
    try {
      final response = await _apiClient.get('/expenses');
      final List<dynamic> expenseData = response.data['expenses'];
      _expenses.value =
          expenseData.map((json) => ExpenseModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      LoggerUtils.error('Error fetching expenses', e, stackTrace);
      rethrow;
    }
  }

  Future<void> fetchBudgets() async {
    try {
      final response = await _apiClient.get('/budgets');
      final List<dynamic> budgetData = response.data['budgets'];
      _budgets.value =
          budgetData.map((json) => BudgetModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      LoggerUtils.error('Error fetching budgets', e, stackTrace);
      rethrow;
    }
  }

  void calculateAnalytics() {
    totalExpenses.value = 0.0;
    categorySpending.clear();

    for (var expense in _expenses) {
      totalExpenses.value += expense.amount;
      categorySpending[expense.category] =
          (categorySpending[expense.category] ?? 0) + expense.amount;
    }

    // Calculate budget progress
    for (var budget in _budgets) {
      final category = budget.category;
      final spent = categorySpending[category] ?? 0.0;
      if (spent > budget.amount) {
        LoggerUtils.warning('Budget exceeded for category: $category');
      }
    }
  }

  List<MapEntry<String, double>> get topSpendingCategories {
    var sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedCategories.take(5).toList();
  }

  // Get monthly spending data for the past 6 months
  List<double> get monthlySpending {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final monthlyTotals = List<double>.filled(6, 0.0);

    for (var expense in _expenses) {
      if (expense.date.isAfter(sixMonthsAgo)) {
        final monthIndex = (expense.date.month - sixMonthsAgo.month) +
            (expense.date.year - sixMonthsAgo.year) * 12;
        if (monthIndex >= 0 && monthIndex < 6) {
          monthlyTotals[monthIndex] += expense.amount;
        }
      }
    }

    return monthlyTotals;
  }

  // Get spending percentage by category
  List<MapEntry<String, double>> get spendingPercentages {
    if (totalExpenses.value == 0) return [];

    return categorySpending.entries.map((entry) {
      return MapEntry(entry.key, (entry.value / totalExpenses.value) * 100);
    }).toList();
  }

  // Get budget progress for each category
  List<MapEntry<String, double>> get budgetProgress {
    return _budgets.map((budget) {
      final spent = categorySpending[budget.category] ?? 0.0;
      return MapEntry(budget.category, (spent / budget.amount) * 100);
    }).toList();
  }

  // Refresh analytics data
  Future<void> refreshData() => fetchAnalytics();
}
