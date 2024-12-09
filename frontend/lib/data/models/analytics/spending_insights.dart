class SpendingInsights {
  final List<SpendingAnomaly> anomalies;
  final List<BudgetAlert> alerts;
  final List<SavingOpportunity> opportunities;
  final Map<String, SpendingPattern> patterns;

  SpendingInsights({
    required this.anomalies,
    required this.alerts,
    required this.opportunities,
    required this.patterns,
  });

  factory SpendingInsights.fromJson(Map<String, dynamic> json) {
    return SpendingInsights(
      anomalies: (json['anomalies'] as List? ?? [])
          .map((e) => SpendingAnomaly.fromJson(e))
          .toList(),
      alerts: (json['alerts'] as List? ?? [])
          .map((e) => BudgetAlert.fromJson(e))
          .toList(),
      opportunities: (json['opportunities'] as List? ?? [])
          .map((e) => SavingOpportunity.fromJson(e))
          .toList(),
      patterns: Map<String, SpendingPattern>.from(
        json['patterns']?.map(
          (key, value) => MapEntry(
            key,
            SpendingPattern.fromJson(value),
          ),
        ) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'anomalies': anomalies.map((e) => e.toJson()).toList(),
    'alerts': alerts.map((e) => e.toJson()).toList(),
    'opportunities': opportunities.map((e) => e.toJson()).toList(),
    'patterns': patterns.map((key, value) => MapEntry(key, value.toJson())),
  };
}

class SpendingAnomaly {
  final String category;
  final double amount;
  final String description;
  final DateTime date;

  SpendingAnomaly({
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory SpendingAnomaly.fromJson(Map<String, dynamic> json) {
    return SpendingAnomaly(
      category: json['category'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      description: json['description'] ?? '',
      date: DateTime.parse(json['date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'amount': amount,
    'description': description,
    'date': date.toIso8601String(),
  };
}

class BudgetAlert {
  final String category;
  final double currentSpending;
  final double budgetLimit;
  final String severity;

  BudgetAlert({
    required this.category,
    required this.currentSpending,
    required this.budgetLimit,
    required this.severity,
  });

  factory BudgetAlert.fromJson(Map<String, dynamic> json) {
    return BudgetAlert(
      category: json['category'] ?? '',
      currentSpending: (json['current_spending'] ?? 0.0).toDouble(),
      budgetLimit: (json['budget_limit'] ?? 0.0).toDouble(),
      severity: json['severity'] ?? 'low',
    );
  }

  Map<String, dynamic> toJson() => {
    'category': category,
    'current_spending': currentSpending,
    'budget_limit': budgetLimit,
    'severity': severity,
  };
}

class SavingOpportunity {
  final String description;
  final double potentialSavings;
  final String category;
  final String recommendation;

  SavingOpportunity({
    required this.description,
    required this.potentialSavings,
    required this.category,
    required this.recommendation,
  });

  factory SavingOpportunity.fromJson(Map<String, dynamic> json) {
    return SavingOpportunity(
      description: json['description'] ?? '',
      potentialSavings: (json['potential_savings'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      recommendation: json['recommendation'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'description': description,
    'potential_savings': potentialSavings,
    'category': category,
    'recommendation': recommendation,
  };
}

class SpendingPattern {
  final String pattern;
  final double averageAmount;
  final String frequency;
  final List<String> relatedCategories;

  SpendingPattern({
    required this.pattern,
    required this.averageAmount,
    required this.frequency,
    required this.relatedCategories,
  });

  factory SpendingPattern.fromJson(Map<String, dynamic> json) {
    return SpendingPattern(
      pattern: json['pattern'] ?? '',
      averageAmount: (json['average_amount'] ?? 0.0).toDouble(),
      frequency: json['frequency'] ?? '',
      relatedCategories: List<String>.from(json['related_categories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    'pattern': pattern,
    'average_amount': averageAmount,
    'frequency': frequency,
    'related_categories': relatedCategories,
  };
}
