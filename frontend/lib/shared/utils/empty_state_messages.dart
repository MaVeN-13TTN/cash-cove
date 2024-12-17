import 'package:flutter/material.dart';

class EmptyStateMessages {
  // Budget-related messages
  static const String noBudgets = 'No Budgets Yet';
  static const String noBudgetsDesc = 'Start managing your finances by creating your first budget.';
  static const String noBudgetCategories = 'No Budget Categories';
  static const String noBudgetCategoriesDesc = 'Add categories to better organize your budgets.';
  
  // Expense-related messages
  static const String noExpenses = 'No Expenses Yet';
  static const String noExpensesDesc = 'Track your spending by adding your first expense.';
  static const String noExpensesInBudget = 'No Expenses in this Budget';
  static const String noExpensesInBudgetDesc = 'Start tracking expenses for this budget.';
  
  // Analytics-related messages
  static const String noAnalyticsData = 'No Data for Analytics';
  static const String noAnalyticsDataDesc = 'Add budgets and expenses to see your financial insights.';
  
  // Action button texts
  static const String createBudget = 'Create Budget';
  static const String addExpense = 'Add Expense';
  static const String addCategory = 'Add Category';
  
  // Get empty state data based on type
  static Map<String, Map<String, String>> get emptyStateData => {
    'budgets': {
      'title': noBudgets,
      'description': noBudgetsDesc,
      'action': createBudget,
    },
    'expenses': {
      'title': noExpenses,
      'description': noExpensesDesc,
      'action': addExpense,
    },
    'budget_categories': {
      'title': noBudgetCategories,
      'description': noBudgetCategoriesDesc,
      'action': addCategory,
    },
    'budget_expenses': {
      'title': noExpensesInBudget,
      'description': noExpensesInBudgetDesc,
      'action': addExpense,
    },
    'analytics': {
      'title': noAnalyticsData,
      'description': noAnalyticsDataDesc,
      'action': createBudget,
    },
  };
  
  // Helper method to get empty state data
  static Map<String, String> getEmptyStateData(String type) {
    return emptyStateData[type] ?? {
      'title': 'No Data Available',
      'description': 'No data is currently available.',
      'action': 'Add New',
    };
  }
  
  // Get appropriate icon for empty state type
  static IconData getEmptyStateIcon(String type) {
    switch (type) {
      case 'budgets':
        return Icons.account_balance_wallet_outlined;
      case 'expenses':
        return Icons.receipt_long_outlined;
      case 'budget_categories':
        return Icons.category_outlined;
      case 'analytics':
        return Icons.analytics_outlined;
      case 'budget_expenses':
        return Icons.money_off_outlined;
      default:
        return Icons.inbox_outlined;
    }
  }
}
