import 'package:json_annotation/json_annotation.dart';

part 'expense_model.g.dart';

@JsonSerializable()
class ExpenseModel {
  final String id;
  final String userId;
  final String? budgetId;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String? description;
  final List<String>? attachments;
  final DateTime createdAt;
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