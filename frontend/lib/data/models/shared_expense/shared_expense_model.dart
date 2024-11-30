import 'package:json_annotation/json_annotation.dart';

part 'shared_expense_model.g.dart';

@JsonSerializable()
class SharedExpenseModel {
  final String id;
  final String expenseId;
  final String groupId;
  final String createdByUserId;
  final List<SharedExpenseMember> members;
  final String splitType; // equal, percentage, amount
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;

  SharedExpenseModel({
    required this.id,
    required this.expenseId,
    required this.groupId,
    required this.createdByUserId,
    required this.members,
    required this.splitType,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SharedExpenseModel.fromJson(Map<String, dynamic> json) => _$SharedExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$SharedExpenseModelToJson(this);
}

@JsonSerializable()
class SharedExpenseMember {
  final String userId;
  final double share; // percentage or amount based on splitType
  final bool isPaid;
  final DateTime? paidAt;

  SharedExpenseMember({
    required this.userId,
    required this.share,
    required this.isPaid,
    this.paidAt,
  });

  factory SharedExpenseMember.fromJson(Map<String, dynamic> json) => _$SharedExpenseMemberFromJson(json);
  Map<String, dynamic> toJson() => _$SharedExpenseMemberToJson(this);
}