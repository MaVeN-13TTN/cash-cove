import 'dart:async';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../data/models/notification/notification_model.dart';
import '../api/api_client.dart';
import '../auth/token_manager.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();
  
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final _apiClient = Get.find<ApiClient>();
  final _tokenManager = Get.find<TokenManager>();

  // Pagination
  int _page = 1;
  bool _hasMore = true;
  static const int _perPage = 20;

  @override
  void onInit() {
    super.onInit();
    _initWebSocket();
    fetchNotifications();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.onClose();
  }

  void _initWebSocket() async {
    final token = await _tokenManager.getToken();
    if (token == null) return;

    final wsUrl = Uri.parse('ws://your-backend-url/ws/notifications/')
        .replace(scheme: 'ws');

    _channel = WebSocketChannel.connect(
      wsUrl,
      protocols: ['Bearer $token'],
    );

    _subscription = _channel?.stream.listen(
      (message) => _handleWebSocketMessage(message),
      onError: (error) => print('WebSocket Error: $error'),
      onDone: () => _reconnectWebSocket(),
    );
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      _initWebSocket();
    });
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final notification = NotificationModel.fromJson(message);
      notifications.insert(0, notification);
      if (!notification.isRead) {
        unreadCount.value++;
      }
      _showNotification(notification);
    } catch (e) {
      print('Error handling notification: $e');
    }
  }

  void _showNotification(NotificationModel notification) {
    Get.snackbar(
      notification.title,
      notification.body,
      duration: const Duration(seconds: 4),
      snackPosition: SnackPosition.TOP,
      onTap: (_) => handleNotificationTap(notification),
    );
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      notifications.clear();
    }

    if (!_hasMore) return;

    try {
      final response = await _apiClient.get(
        '/notifications/',
        queryParameters: {'page': _page, 'per_page': _perPage},
      );

      final List<NotificationModel> newNotifications = (response.data['results'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();

      if (newNotifications.length < _perPage) {
        _hasMore = false;
      }

      notifications.addAll(newNotifications);
      _page++;

      // Update unread count
      unreadCount.value = notifications.where((n) => !n.isRead).length;
    } catch (e) {
      print('Error fetching notifications: $e');
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.post('/notifications/$notificationId/read/');
      
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = notifications[index];
        notifications[index] = NotificationModel(
          id: notification.id,
          userId: notification.userId,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          data: notification.data,
          isRead: true,
          createdAt: notification.createdAt,
          readAt: DateTime.now(),
          payload: notification.payload,
        );
        unreadCount.value--;
      }
    } catch (e) {
      print('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.post('/notifications/mark-all-read/');
      
      notifications.assignAll(notifications.map((notification) => NotificationModel(
        id: notification.id,
        userId: notification.userId,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        data: notification.data,
        isRead: true,
        createdAt: notification.createdAt,
        readAt: DateTime.now(),
        payload: notification.payload,
      )).toList());
      
      unreadCount.value = 0;
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  void handleNotificationTap(NotificationModel notification) {
    // Mark as read
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Handle navigation based on notification type
    switch (notification.type) {
      case 'BUDGET_ALERT':
      case 'BUDGET_EXCEEDED':
        final budgetId = notification.data?['budget_id'];
        if (budgetId != null) {
          Get.toNamed('/budgets/$budgetId');
        }
        break;
      case 'EXPENSE_ALERT':
      case 'RECURRING_EXPENSE':
        final expenseId = notification.data?['expense_id'];
        if (expenseId != null) {
          Get.toNamed('/expenses/$expenseId');
        }
        break;
      case 'THRESHOLD_REACHED':
        Get.toNamed('/analytics');
        break;
      default:
        // Handle other notification types
        break;
    }
  }
}
