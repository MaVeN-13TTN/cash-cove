import 'package:json_annotation/json_annotation.dart';
import 'shared_expense_enums.dart';
import 'participant_share_model.dart';

part 'shared_expense_model.g.dart';

@JsonSerializable()
class SharedExpenseModel {
  final String id;
  final String title;
  final String description;
  final String expenseId;
  final String groupId;
  final String createdByUserId;
  final String creatorName;
  final double amount;
  final SplitMethod splitMethod;
  final SharedExpenseStatus status;
  final String? category;
  final DateTime? dueDate;
  final String? reminderFrequency;
  final Map<String, dynamic>? metadata;
  final List<ParticipantShare> participantShares;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed property to get the total amount paid across all participants
  double get totalPaid => participantShares.fold(0, (sum, share) => sum + share.amountPaid);

  /// Computed property to get the remaining amount to be paid
  double get remainingAmount => amount - totalPaid;

  /// Computed property to check if the expense is fully settled
  bool get isSettled => status == SharedExpenseStatus.SETTLED;

  /// Computed property to check if the expense can be edited
  bool get canEdit => status != SharedExpenseStatus.SETTLED && 
                      status != SharedExpenseStatus.CANCELLED;

  const SharedExpenseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.expenseId,
    required this.groupId,
    required this.createdByUserId,
    required this.creatorName,
    required this.amount,
    required this.splitMethod,
    required this.status,
    this.category,
    this.dueDate,
    this.reminderFrequency,
    this.metadata,
    required this.participantShares,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [SharedExpenseModel] instance from a JSON map
  factory SharedExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$SharedExpenseModelFromJson(json);

  /// Converts this [SharedExpenseModel] instance to a JSON map
  Map<String, dynamic> toJson() => _$SharedExpenseModelToJson(this);

  /// Creates a copy of this [SharedExpenseModel] with the given fields replaced
  SharedExpenseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? expenseId,
    String? groupId,
    String? createdByUserId,
    String? creatorName,
    double? amount,
    SplitMethod? splitMethod,
    SharedExpenseStatus? status,
    String? category,
    DateTime? dueDate,
    String? reminderFrequency,
    Map<String, dynamic>? metadata,
    List<ParticipantShare>? participantShares,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SharedExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      expenseId: expenseId ?? this.expenseId,
      groupId: groupId ?? this.groupId,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      creatorName: creatorName ?? this.creatorName,
      amount: amount ?? this.amount,
      splitMethod: splitMethod ?? this.splitMethod,
      status: status ?? this.status,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      reminderFrequency: reminderFrequency ?? this.reminderFrequency,
      metadata: metadata ?? this.metadata,
      participantShares: participantShares ?? this.participantShares,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'SharedExpenseModel(id: $id, title: $title, amount: $amount, status: $status)';
  }
}