import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final double amount;
  
  @HiveField(4)
  final String currency;
  
  @HiveField(5)
  final DateTime startDate;
  
  @HiveField(6)
  final DateTime endDate;
  
  @HiveField(7)
  final String category;
  
  @HiveField(8)
  final double spentAmount;
  
  @HiveField(9)
  final DateTime createdAt;
  
  @HiveField(10)
  final DateTime updatedAt;
  
  @HiveField(11)
  final String color;
  
  @HiveField(12)
  final String recurrence;
  
  @HiveField(13)
  final double notificationThreshold;
  
  @HiveField(14)
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