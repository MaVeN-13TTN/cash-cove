import 'dart:async';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logging/logging.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/api_exceptions.dart';
import '../auth/token_manager.dart';
import '../../../data/models/notification/notification_model.dart';

class NotificationService extends GetxService {
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  final ApiClient _apiClient;
  final TokenManager _tokenManager;
  final Logger _logger;

  // Pagination
  int _page = 1;
  static const int _perPage = 20;
  bool _hasMore = true;

  NotificationService({
    ApiClient? apiClient,
    TokenManager? tokenManager,
  })  : _apiClient = apiClient ?? Get.find<ApiClient>(),
        _tokenManager = tokenManager ?? Get.find<TokenManager>(),
        _logger = Logger('NotificationService');

  @override
  void onInit() {
    super.onInit();
    _initializeWebSocket();
    fetchNotifications();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _channel?.sink.close();
    super.onClose();
  }

  Future<void> fetchNotifications({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      notifications.clear();
    }

    if (!_hasMore || isLoading.value) return;

    try {
      isLoading.value = true;
      final response = await _apiClient.dio.get(
        '/notifications/',
        queryParameters: {
          'page': _page,
          'per_page': _perPage,
        },
      );

      final List<NotificationModel> newNotifications =
          (response.data['results'] as List)
              .map((json) => NotificationModel.fromJson(json))
              .toList();

      if (newNotifications.length < _perPage) {
        _hasMore = false;
      }

      notifications.addAll(newNotifications);
      _updateUnreadCount();
      _page++;
    } catch (e) {
      _logger.severe('Error fetching notifications', e);
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiClient.dio.post('/notifications/$notificationId/read/');

      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        final notification = notifications[index];
        notifications[index] = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _updateUnreadCount();
      }
    } catch (e) {
      _logger.severe('Error marking notification as read', e);
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.markAllNotificationsRead,
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
        ),
      );

      notifications.assignAll(notifications
          .map(
            (notification) => notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            ),
          )
          .toList());

      _updateUnreadCount();
    } catch (e) {
      _logger.severe('Error marking all notifications as read', e);
      throw ApiException('Failed to mark notifications as read');
    }
  }

  Future<void> bulkAction({
    required List<String> notificationIds,
    required String action,
  }) async {
    try {
      await _apiClient.dio.post(
        ApiEndpoints.notificationBulkAction,
        data: {
          'notification_ids': notificationIds,
          'action': action,
        },
      );

      if (action == 'mark_read') {
        notifications.assignAll(notifications.map((notification) {
          if (notificationIds.contains(notification.id)) {
            return notification.copyWith(
              isRead: true,
              readAt: DateTime.now(),
            );
          }
          return notification;
        }).toList());

        _updateUnreadCount();
      }
    } catch (e) {
      _logger.severe('Error performing bulk action on notifications', e);
      throw ApiException('Failed to perform bulk action on notifications');
    }
  }

  Future<Map<String, int>> getNotificationCounts() async {
    try {
      final response = await _apiClient.dio.get(
        ApiEndpoints.notificationCounts,
        options: Options(
          headers: {'Cache-Control': 'max-age=60'}, // 1 minute cache
        ),
      );
      return Map<String, int>.from(response.data);
    } catch (e) {
      _logger.severe('Error fetching notification counts', e);
      throw ApiException('Failed to fetch notification counts');
    }
  }

  Future<void> _initializeWebSocket() async {
    final token = await _tokenManager.getAccessToken();
    // Check if token exists before proceeding
    if (token == null || token.isEmpty) return;

    final wsUrl = 'ws://localhost:8000/ws/notifications/?token=$token';
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    _subscription = _channel?.stream.listen(
      (data) {
        final notification = NotificationModel.fromJson(data);
        notifications.insert(0, notification);
        if (notification.isRead == false) {
          unreadCount.value++;
        }
      },
      onError: (error) {
        _logger.severe('WebSocket error', error);
      },
      onDone: () {
        _logger.info('WebSocket connection closed');
      },
    );
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void handleNotificationTap(NotificationModel notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }
    // Handle navigation or action based on notification type
    if (notification.actionUrl != null) {
      // Handle navigation
    }
  }
}
