class SpendingAnalytics {
  final Map<String, double> categorySpending;
  final double totalSpending;
  final DateTime startDate;
  final DateTime endDate;

  SpendingAnalytics({
    required this.categorySpending,
    required this.totalSpending,
    required this.startDate,
    required this.endDate,
  });

  factory SpendingAnalytics.fromJson(Map<String, dynamic> json) {
    return SpendingAnalytics(
      categorySpending: Map<String, double>.from(json['category_spending'] ?? {}),
      totalSpending: (json['total_spending'] ?? 0.0).toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'category_spending': categorySpending,
    'total_spending': totalSpending,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
  };
}
