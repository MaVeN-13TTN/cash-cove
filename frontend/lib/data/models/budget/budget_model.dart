import 'package:json_annotation/json_annotation.dart';

part 'budget_model.g.dart';

@JsonSerializable()
class BudgetModel {
  final String id;
  final String userId;
  final String name;
  final double amount;
  final String currency;
  final DateTime startDate;
  final DateTime endDate;
  final String category;
  final double spentAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.spentAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingAmount => amount - spentAmount;
  double get spentPercentage => (spentAmount / amount) * 100;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => _$BudgetModelFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetModelToJson(this);
}