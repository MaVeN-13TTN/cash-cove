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
  final String color;
  final String recurrence;
  final double notificationThreshold;
  final String description;

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
    this.color = '#6366F1',  // Default color
    this.recurrence = 'NONE',  // Default recurrence
    this.notificationThreshold = 80.0,  // Default threshold
    this.description = '',  // Default description
  });

  double get remainingAmount => amount - spentAmount;
  double get spentPercentage => (spentAmount / amount) * 100;

  factory BudgetModel.fromJson(Map<String, dynamic> json) => _$BudgetModelFromJson(json);
  Map<String, dynamic> toJson() => _$BudgetModelToJson(this);
}