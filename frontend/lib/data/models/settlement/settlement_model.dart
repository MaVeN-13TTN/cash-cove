import 'dart:convert';
import '../user/user_model.dart';

class SettlementModel {
  final String id;
  final String groupId;
  final UserModel payer;
  final UserModel receiver;
  final double amount;
  final DateTime createdAt;
  final bool isPaid;
  final DateTime? paidAt;
  final String? notes;

  SettlementModel({
    required this.id,
    required this.groupId,
    required this.payer,
    required this.receiver,
    required this.amount,
    required this.createdAt,
    this.isPaid = false,
    this.paidAt,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'payer': payer.toJson(),
      'receiver': receiver.toJson(),
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'is_paid': isPaid,
      'paid_at': paidAt?.toIso8601String(),
      'notes': notes,
    };
  }

  factory SettlementModel.fromJson(Map<String, dynamic> json) {
    return SettlementModel(
      id: json['id'],
      groupId: json['group_id'],
      payer: UserModel.fromJson(json['payer']),
      receiver: UserModel.fromJson(json['receiver']),
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      isPaid: json['is_paid'] ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
