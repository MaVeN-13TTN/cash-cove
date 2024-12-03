import 'package:get/get.dart';
import '../../../core/utils/logger_utils.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../../../data/models/notification/notification_model.dart';
import '../../../core/services/notifications/web_socket_service.dart';

class NotificationsController extends GetxController {
  final _notificationService = Get.find<NotificationService>();
  final WebSocketService _webSocketService = WebSocketService();

  // Reactive variables
  RxList<NotificationModel> get notifications => 
      _notificationService.notifications;
  RxInt get unreadCount => _notificationService.unreadCount;
  RxBool isLoading = false.obs;
  RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    _webSocketService.connect('ws://your-backend-url/ws/notifications');
    refreshNotifications();
  }

  @override
  void onClose() {
    _webSocketService.disconnect();
    super.onClose();
  }

  void sendMessage(String message) {
    _webSocketService.sendMessage(message);
  }

  Future<void> refreshNotifications() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      await _notificationService.fetchNotifications(refresh: true);
    } catch (e) {
      hasError.value = true;
      LoggerUtils.error('Error refreshing notifications', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreNotifications() async {
    if (isLoading.value) return;

    try {
      await _notificationService.fetchNotifications();
    } catch (e) {
      LoggerUtils.error('Error loading more notifications', e);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      LoggerUtils.error('Error marking notification as read', e);
      Get.snackbar(
        'Error',
        'Failed to mark notification as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      Get.snackbar(
        'Success',
        'All notifications marked as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      LoggerUtils.error('Error marking all notifications as read', e);
      Get.snackbar(
        'Error',
        'Failed to mark all notifications as read',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void handleNotificationTap(NotificationModel notification) {
    _notificationService.handleNotificationTap(notification);
  }
}
