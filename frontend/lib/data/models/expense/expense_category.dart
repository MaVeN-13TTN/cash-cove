enum ExpenseCategory {
  food,
  transportation,
  housing,
  utilities,
  entertainment,
  healthcare,
  shopping,
  education,
  travel,
  investment,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.housing:
        return 'Housing & Rent';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.healthcare:
        return 'Healthcare';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.investment:
        return 'Investment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.transportation:
        return '🚗';
      case ExpenseCategory.housing:
        return '🏠';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.entertainment:
        return '🎮';
      case ExpenseCategory.healthcare:
        return '🏥';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.travel:
        return '✈️';
      case ExpenseCategory.investment:
        return '📈';
      case ExpenseCategory.other:
        return '📌';
    }
  }
}