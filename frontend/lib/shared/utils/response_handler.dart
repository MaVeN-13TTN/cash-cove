import 'package:flutter/material.dart';
import '../widgets/empty_state.dart';
import 'empty_state_messages.dart';

class ResponseHandler {
  /// Checks if the response is empty and returns appropriate widget
  static Widget handleEmptyResponse<T>({
    required List<T> data,
    required String type,
    VoidCallback? onAction,
    Widget Function(List<T>)? onData,
  }) {
    if (data.isEmpty) {
      final stateData = EmptyStateMessages.getEmptyStateData(type);
      return EmptyState(
        title: stateData['title']!,
        description: stateData['description']!,
        icon: EmptyStateMessages.getEmptyStateIcon(type),
        onAction: onAction,
        actionText: stateData['action'],
      );
    }
    return onData?.call(data) ?? const SizedBox();
  }

  /// Checks if response is empty and returns appropriate boolean
  static bool isEmptyResponse(dynamic response) {
    if (response is List) {
      return response.isEmpty;
    }
    if (response is Map) {
      return response.isEmpty;
    }
    return response == null;
  }
}
