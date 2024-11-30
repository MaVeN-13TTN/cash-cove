import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  @JsonKey(name: 'message')
  final String body;
  final String type; // budget_alert, expense_reminder, shared_expense_request, etc.
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? payload;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.payload,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}