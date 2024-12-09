class ExpenseSummaryModel {
  final double totalExpenses;
  final double totalIncome;
  final double remainingBudget;

  ExpenseSummaryModel({
    required this.totalExpenses,
    required this.totalIncome,
    required this.remainingBudget,
  });

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryModel(
      totalExpenses: json['totalExpenses']?.toDouble() ?? 0.0,
      totalIncome: json['totalIncome']?.toDouble() ?? 0.0,
      remainingBudget: json['remainingBudget']?.toDouble() ?? 0.0,
    );
  }
}
