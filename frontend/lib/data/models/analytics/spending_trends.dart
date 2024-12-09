class SpendingTrends {
  final List<MonthlySpending> monthlyTrends;
  final Map<String, List<double>> categoryTrends;
  final double averageMonthlySpending;
  final double spendingGrowthRate;

  SpendingTrends({
    required this.monthlyTrends,
    required this.categoryTrends,
    required this.averageMonthlySpending,
    required this.spendingGrowthRate,
  });

  factory SpendingTrends.fromJson(Map<String, dynamic> json) {
    return SpendingTrends(
      monthlyTrends: (json['monthly_trends'] as List? ?? [])
          .map((e) => MonthlySpending.fromJson(e))
          .toList(),
      categoryTrends: Map<String, List<double>>.from(
        json['category_trends']?.map(
          (key, value) => MapEntry(
            key,
            (value as List).map((e) => (e as num).toDouble()).toList(),
          ),
        ) ?? {},
      ),
      averageMonthlySpending: (json['average_monthly_spending'] ?? 0.0).toDouble(),
      spendingGrowthRate: (json['spending_growth_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'monthly_trends': monthlyTrends.map((e) => e.toJson()).toList(),
    'category_trends': categoryTrends,
    'average_monthly_spending': averageMonthlySpending,
    'spending_growth_rate': spendingGrowthRate,
  };
}

class MonthlySpending {
  final String month;
  final double amount;
  final Map<String, double> categoryBreakdown;

  MonthlySpending({
    required this.month,
    required this.amount,
    required this.categoryBreakdown,
  });

  factory MonthlySpending.fromJson(Map<String, dynamic> json) {
    return MonthlySpending(
      month: json['month'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      categoryBreakdown: Map<String, double>.from(json['category_breakdown'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'month': month,
    'amount': amount,
    'category_breakdown': categoryBreakdown,
  };
}
