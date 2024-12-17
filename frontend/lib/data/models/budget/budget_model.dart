import 'package:json_annotation/json_annotation.dart';
import 'package:hive/hive.dart';

part 'budget_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 0)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  @JsonKey(includeFromJson: false, includeToJson: false)  // Don't serialize userId as it's handled by backend
  final String userId;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final double amount;
  
  @HiveField(4)
  final String currency;
  
  @HiveField(5)
  @JsonKey(
    name: 'start_date',
    fromJson: _dateFromJson,
    toJson: _dateToJson,
  )
  final DateTime startDate;
  
  @HiveField(6)
  @JsonKey(
    name: 'end_date',
    fromJson: _dateFromJson,
    toJson: _dateToJson,
  )
  final DateTime endDate;
  
  @HiveField(7)
  final String category;
  
  @HiveField(8)
  @JsonKey(name: 'remaining_amount')
  final double remainingAmount;
  
  @HiveField(9)
  @JsonKey(
    name: 'created_at',
    fromJson: _dateFromJson,
    toJson: _dateToJson,
  )
  final DateTime createdAt;
  
  @HiveField(10)
  @JsonKey(
    name: 'updated_at',
    fromJson: _dateFromJson,
    toJson: _dateToJson,
  )
  final DateTime updatedAt;
  
  @HiveField(11)
  final String? color;
  
  @HiveField(12)
  final String recurrence;
  
  @HiveField(13)
  @JsonKey(name: 'notification_threshold')
  final double notificationThreshold;
  
  @HiveField(14)
  final String description;
  
  @HiveField(15)
  @JsonKey(name: 'is_active')
  final bool isActive;
  
  @HiveField(16)
  @JsonKey(name: 'is_expired')
  final bool isExpired;
  
  @HiveField(17)
  @JsonKey(name: 'utilization_percentage')
  final double utilizationPercentage;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.amount,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.category,
    required this.remainingAmount,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    required this.recurrence,
    required this.notificationThreshold,
    required this.description,
    required this.isActive,
    required this.isExpired,
    required this.utilizationPercentage,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) =>
      _$BudgetModelFromJson(json);

  Map<String, dynamic> toJson() => _$BudgetModelToJson(this);

  static DateTime _dateFromJson(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    }
    return DateTime.fromMillisecondsSinceEpoch(date * 1000);
  }

  static String _dateToJson(DateTime date) {
    return date.toIso8601String();
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? name,
    double? amount,
    String? currency,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    double? remainingAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    String? recurrence,
    double? notificationThreshold,
    String? description,
    bool? isActive,
    bool? isExpired,
    double? utilizationPercentage,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      category: category ?? this.category,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      recurrence: recurrence ?? this.recurrence,
      notificationThreshold: notificationThreshold ?? this.notificationThreshold,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      isExpired: isExpired ?? this.isExpired,
      utilizationPercentage: utilizationPercentage ?? this.utilizationPercentage,
    );
  }
}