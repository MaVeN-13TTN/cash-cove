enum BudgetCategory {
  monthly,
  weekly,
  yearly,
  custom;

  String get displayName {
    switch (this) {
      case BudgetCategory.monthly:
        return 'Monthly Budget';
      case BudgetCategory.weekly:
        return 'Weekly Budget';
      case BudgetCategory.yearly:
        return 'Yearly Budget';
      case BudgetCategory.custom:
        return 'Custom Budget';
    }
  }

  String get icon {
    switch (this) {
      case BudgetCategory.monthly:
        return '📅';
      case BudgetCategory.weekly:
        return '📆';
      case BudgetCategory.yearly:
        return '📊';
      case BudgetCategory.custom:
        return '⚙️';
    }
  }

  int get defaultDurationInDays {
    switch (this) {
      case BudgetCategory.monthly:
        return 30;
      case BudgetCategory.weekly:
        return 7;
      case BudgetCategory.yearly:
        return 365;
      case BudgetCategory.custom:
        return 0;
    }
  }
}