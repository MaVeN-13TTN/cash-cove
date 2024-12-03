import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class TransactionModel extends HiveObject {
  @HiveField(0)
  @JsonKey(name: 'id')
  final String id;

  @HiveField(1)
  @JsonKey(name: 'amount')
  final double amount;

  @HiveField(2)
  @JsonKey(name: 'category')
  final String category;

  @HiveField(3)
  @JsonKey(name: 'date')
  final DateTime date;

  @HiveField(4)
  @JsonKey(name: 'description')
  final String description;

  @HiveField(5)
  @JsonKey(name: 'budget_id')
  final String? budgetId;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.description,
    this.budgetId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => 
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);

  @override
  String toString() {
    return 'TransactionModel(id: $id, amount: $amount, category: $category, date: $date, description: $description, budgetId: $budgetId)';
  }
}
