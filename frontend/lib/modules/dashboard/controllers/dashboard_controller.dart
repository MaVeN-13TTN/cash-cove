import 'package:flutter/material.dart' show DateUtils;
import 'package:get/get.dart';
import '../../../data/models/budget/budget_model.dart';
import '../../../data/models/transaction/transaction_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/transaction_repository.dart';

class DashboardController extends GetxController {
  final BudgetRepository _budgetRepository;
  final TransactionRepository _transactionRepository;

  DashboardController({
    required BudgetRepository budgetRepository,
    required TransactionRepository transactionRepository,
  })  : _budgetRepository = budgetRepository,
        _transactionRepository = transactionRepository;

  // Observable states
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _budgets = <BudgetModel>[].obs;
  final _recentTransactions = <TransactionModel>[].obs;
  final _totalSpent = 0.0.obs;
  final _totalBudget = 0.0.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<BudgetModel> get budgets => _budgets;
  List<TransactionModel> get recentTransactions => _recentTransactions;
  double get totalSpent => _totalSpent.value;
  double get totalBudget => _totalBudget.value;
  double get remainingBudget => totalBudget - totalSpent;
  double get spendingPercentage =>
      totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // Fetch budgets
      final budgets = await _budgetRepository.getBudgets();
      _budgets.assignAll(budgets);

      // Calculate total budget
      _totalBudget.value = budgets.fold(
        0.0,
        (sum, budget) => sum + budget.amount,
      );

      // Fetch recent transactions
      final transactions = await _transactionRepository.getTransactions();
      _recentTransactions.assignAll(transactions);

      // Calculate total spent
      _totalSpent.value = transactions.fold(
        0.0,
        (sum, transaction) => sum + transaction.amount,
      );
    } catch (e) {
      _error.value = 'Failed to load dashboard data';
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refreshDashboard() async {
    await fetchDashboardData();
  }

  List<TransactionModel> getTransactionsForBudget(String budgetId) {
    return _recentTransactions.where((t) => t.budgetId == budgetId).toList();
  }

  double getSpentForBudget(String budgetId) {
    return getTransactionsForBudget(budgetId).fold(
      0.0,
      (sum, transaction) => sum + transaction.amount,
    );
  }

  String getRemainingBudgetText() {
    if (remainingBudget >= 0) {
      return 'You have \$${remainingBudget.toStringAsFixed(2)} left to spend';
    } else {
      return 'You are over budget by \$${(-remainingBudget).toStringAsFixed(2)}';
    }
  }

  String getSpendingAdvice() {
    final daysLeft =
        DateUtils.getDaysInMonth(DateTime.now().year, DateTime.now().month) -
            DateTime.now().day;
    final dailyBudget = remainingBudget / daysLeft;

    if (remainingBudget <= 0) {
      return 'You have exceeded your budget. Try to reduce spending.';
    } else if (spendingPercentage > 90) {
      return 'You are close to your budget limit. Be careful with spending.';
    } else if (spendingPercentage > 75) {
      return 'You can spend about \$${dailyBudget.toStringAsFixed(2)} per day for the rest of the month.';
    } else {
      return 'You are well within your budget. Keep it up!';
    }
  }
}
