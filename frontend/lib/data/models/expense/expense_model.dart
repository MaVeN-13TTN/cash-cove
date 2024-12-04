import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'expense_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String? budgetId;
  
  @HiveField(3)
  final String title;
  
  @HiveField(4)
  final double amount;
  
  @HiveField(5)
  final String currency;
  
  @HiveField(6)
  final DateTime date;
  
  @HiveField(7)
  final String category;
  
  @HiveField(8)
  final String? description;
  
  @HiveField(9)
  final List<String>? attachments;
  
  @HiveField(10)
  final DateTime createdAt;
  
  @HiveField(11)
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.userId,
    this.budgetId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.date,
    required this.category,
    this.description,
    this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => _$ExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);
}