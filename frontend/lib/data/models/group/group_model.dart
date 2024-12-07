import 'dart:convert';
import '../user/user_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final String createdBy;
  final List<UserModel> members;
  final double totalExpenses;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.createdBy,
    required this.members,
    this.totalExpenses = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'members': members.map((member) => member.toJson()).toList(),
      'total_expenses': totalExpenses,
    };
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'],
      members: (json['members'] as List)
          .map((member) => UserModel.fromJson(member))
          .toList(),
      totalExpenses: (json['total_expenses'] ?? 0.0).toDouble(),
    );
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
