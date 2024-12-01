import 'package:json_annotation/json_annotation.dart';

part 'participant_share_model.g.dart';

@JsonSerializable()
class ParticipantShare {
  final String id;
  final String participantId;
  final String participantName;
  final String participantEmail;
  final double percentage;
  final int shares;
  final double amount;
  final double amountPaid;
  final String? notes;
  final DateTime? lastReminded;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Computed property to check if the share is fully paid
  bool get isPaid => amountPaid >= amount;

  /// Computed property to get the remaining amount to be paid
  double get remainingAmount => amount - amountPaid;

  const ParticipantShare({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantEmail,
    required this.percentage,
    required this.shares,
    required this.amount,
    required this.amountPaid,
    this.notes,
    this.lastReminded,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [ParticipantShare] instance from a JSON map
  factory ParticipantShare.fromJson(Map<String, dynamic> json) =>
      _$ParticipantShareFromJson(json);

  /// Converts this [ParticipantShare] instance to a JSON map
  Map<String, dynamic> toJson() => _$ParticipantShareToJson(this);

  /// Creates a copy of this [ParticipantShare] with the given fields replaced
  ParticipantShare copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantEmail,
    double? percentage,
    int? shares,
    double? amount,
    double? amountPaid,
    String? notes,
    DateTime? lastReminded,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ParticipantShare(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantEmail: participantEmail ?? this.participantEmail,
      percentage: percentage ?? this.percentage,
      shares: shares ?? this.shares,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      notes: notes ?? this.notes,
      lastReminded: lastReminded ?? this.lastReminded,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ParticipantShare(id: $id, participantName: $participantName, amount: $amount, amountPaid: $amountPaid)';
  }
}
