import 'package:flutter/material.dart' show DateUtils;
import 'package:get/get.dart';
import 'package:logging/logging.dart';
import '../../../data/models/budget/budget_model.dart';
import '../../../data/models/expense/expense_model.dart';
import '../../../data/repositories/budget_repository.dart';
import '../../../data/repositories/expense_repository.dart';

class DashboardController extends GetxController {
  final BudgetRepository _budgetRepository;
  final ExpenseRepository _expenseRepository;
  static final _log = Logger('DashboardController');

  DashboardController({
    required BudgetRepository budgetRepository,
    required ExpenseRepository expenseRepository,
  })  : _budgetRepository = budgetRepository,
        _expenseRepository = expenseRepository;

  // Observable states
  final _isLoading = false.obs;
  final _error = Rx<String?>(null);
  final _budgets = <BudgetModel>[].obs;
  final _recentExpenses = <ExpenseModel>[].obs;
  final _totalSpent = 0.0.obs;
  final _totalBudget = 0.0.obs;
  final _isUsingDummyData = true.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<BudgetModel> get budgets => _budgets;
  List<ExpenseModel> get recentExpenses => _recentExpenses;
  double get totalSpent => _totalSpent.value;
  double get totalBudget => _totalBudget.value;
  double get remainingBudget => totalBudget - totalSpent;
  double get spendingPercentage =>
      totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0;
  bool get isUsingDummyData => _isUsingDummyData.value;

  @override
  void onInit() {
    super.onInit();
    _checkUserBudgetsAndExpenses();
  }

  @override
  void onReady() {
    super.onReady();
    _resetStateAndCheckData();
  }

  void _resetStateAndCheckData() {
    _isUsingDummyData.value = true; // Reset to dummy data by default
    _checkUserBudgetsAndExpenses();
  }

  void _checkUserBudgetsAndExpenses() async {
    try {
      _isLoading.value = true;
      _log.info('Checking for user data...');

      // Check for existing budgets
      final budgetsExist = await _budgetRepository.getBudgets().then(
            (budgets) => budgets.isNotEmpty,
            onError: (error) {
              _log.severe('Error fetching budgets: $error');
              return false;
            },
          );

      // Check for existing expenses
      final expensesExist = await _expenseRepository.getExpenses().then(
            (expenses) => expenses.isNotEmpty,
            onError: (error) {
              _log.severe('Error fetching expenses: $error');
              return false;
            },
          );

      _log.info('Budgets exist: $budgetsExist, Expenses exist: $expensesExist');

      if (budgetsExist || expensesExist) {
        await fetchDashboardData();
      } else {
        _loadDummyData();
      }
    } catch (e) {
      _log.severe('Error checking user data: $e');
      _loadDummyData();
    } finally {
      _isLoading.value = false;
    }
  }

  void _loadDummyData() {
    final now = DateTime.now();
    
    // Dummy budgets
    final dummyBudgets = [
      BudgetModel(
        id: 'dummy1',
        userId: 'user123',
        name: 'Monthly Budget',
        amount: 1000.0,
        currency: 'USD',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        category: 'General',
        spentAmount: 0.0,
        createdAt: now,
        updatedAt: now,
        color: '#FF4081',
        recurrence: 'monthly',
        notificationThreshold: 0.8,
        description: 'Monthly household budget',
      ),
    ];

    // Dummy expenses
    final dummyExpenses = [
      ExpenseModel(
        id: 'exp1',
        userId: 'user123',
        title: 'Weekly Groceries',
        amount: 50.0,
        currency: 'USD',
        date: now.subtract(const Duration(days: 1)),
        category: 'Groceries',
        description: 'Weekly groceries',
        budgetId: 'dummy1',
        createdAt: now,
        updatedAt: now,
      ),
      ExpenseModel(
        id: 'exp2',
        userId: 'user123',
        title: 'Bus Fare',
        amount: 30.0,
        currency: 'USD',
        date: now.subtract(const Duration(days: 2)),
        category: 'Transportation',
        description: 'Bus fare',
        budgetId: 'dummy1',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    _budgets.value = dummyBudgets;
    _recentExpenses.value = dummyExpenses;
    _updateTotals();
    _isUsingDummyData.value = true;
  }

  Future<void> fetchDashboardData() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      // Fetch budgets
      final budgets = await _budgetRepository.getBudgets();
      _budgets.value = budgets;

      // Fetch recent expenses
      final expenses = await _expenseRepository.getExpenses(
        startDate: DateUtils.addMonthsToMonthDate(DateTime.now(), -1),
        endDate: DateTime.now(),
      );
      _recentExpenses.value = expenses;

      _updateTotals();
      _isUsingDummyData.value = false;
    } catch (e) {
      _log.severe('Error fetching dashboard data: $e');
      _error.value = 'Failed to load dashboard data';
      _loadDummyData();
    } finally {
      _isLoading.value = false;
    }
  }

  void _updateTotals() {
    _totalBudget.value = _budgets.fold(
      0,
      (sum, budget) => sum + budget.amount,
    );

    _totalSpent.value = _recentExpenses.fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  List<ExpenseModel> getExpensesByBudget(String budgetId) {
    return _recentExpenses.where((expense) => expense.budgetId == budgetId).toList();
  }

  double getBudgetSpending(String budgetId) {
    return getExpensesByBudget(budgetId).fold(
      0,
      (sum, expense) => sum + expense.amount,
    );
  }

  void refreshDashboard() {
    _resetStateAndCheckData();
  }
}
