class BudgetUtilization {
  final Map<String, double> categoryUtilization;
  final double totalBudget;
  final double totalSpent;
  final double utilizationRate;
  final String month;

  BudgetUtilization({
    required this.categoryUtilization,
    required this.totalBudget,
    required this.totalSpent,
    required this.utilizationRate,
    required this.month,
  });

  factory BudgetUtilization.fromJson(Map<String, dynamic> json) {
    return BudgetUtilization(
      categoryUtilization: Map<String, double>.from(json['category_utilization'] ?? {}),
      totalBudget: (json['total_budget'] ?? 0.0).toDouble(),
      totalSpent: (json['total_spent'] ?? 0.0).toDouble(),
      utilizationRate: (json['utilization_rate'] ?? 0.0).toDouble(),
      month: json['month'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'category_utilization': categoryUtilization,
    'total_budget': totalBudget,
    'total_spent': totalSpent,
    'utilization_rate': utilizationRate,
    'month': month,
  };
}
