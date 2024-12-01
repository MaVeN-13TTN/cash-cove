/// Enums for shared expense types and statuses
enum SplitMethod {
  EQUAL,
  PERCENTAGE,
  CUSTOM,
  SHARES;

  String get displayName {
    switch (this) {
      case SplitMethod.EQUAL:
        return 'Split Equally';
      case SplitMethod.PERCENTAGE:
        return 'Split by Percentage';
      case SplitMethod.CUSTOM:
        return 'Custom Split';
      case SplitMethod.SHARES:
        return 'Split by Shares';
    }
  }
}

enum SharedExpenseStatus {
  PENDING,
  ACTIVE,
  SETTLED,
  CANCELLED,
  DISPUTED;

  String get displayName {
    switch (this) {
      case SharedExpenseStatus.PENDING:
        return 'Pending';
      case SharedExpenseStatus.ACTIVE:
        return 'Active';
      case SharedExpenseStatus.SETTLED:
        return 'Settled';
      case SharedExpenseStatus.CANCELLED:
        return 'Cancelled';
      case SharedExpenseStatus.DISPUTED:
        return 'Disputed';
    }
  }
}
