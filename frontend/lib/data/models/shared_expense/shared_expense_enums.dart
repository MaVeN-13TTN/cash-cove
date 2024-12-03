/// Enums for shared expense types and statuses
enum SplitMethod {
  equal,
  percentage,
  custom,
  shares;

  String get displayName {
    switch (this) {
      case SplitMethod.equal:
        return 'Split Equally';
      case SplitMethod.percentage:
        return 'Split by Percentage';
      case SplitMethod.custom:
        return 'Custom Split';
      case SplitMethod.shares:
        return 'Split by Shares';
    }
  }
}

enum SharedExpenseStatus {
  pending,
  active,
  settled,
  cancelled,
  disputed;

  String get displayName {
    switch (this) {
      case SharedExpenseStatus.pending:
        return 'Pending';
      case SharedExpenseStatus.active:
        return 'Active';
      case SharedExpenseStatus.settled:
        return 'Settled';
      case SharedExpenseStatus.cancelled:
        return 'Cancelled';
      case SharedExpenseStatus.disputed:
        return 'Disputed';
    }
  }
}
