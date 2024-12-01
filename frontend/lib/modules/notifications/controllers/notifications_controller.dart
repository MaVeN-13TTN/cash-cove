import 'package:get/get.dart';
import '../../../core/services/notifications/notification_service.dart';
import '../../../data/models/notification/notification_model.dart';

class NotificationController extends GetxController {
  final _notificationService = Get.find<NotificationService>();

  // Reactive variables
  RxList<NotificationModel> get notifications => _notificationService.notifications;
  RxInt get unreadCount => _notificationService.unreadCount;
  RxBool isLoading = false.obs;
  RxBool hasError = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshNotifications();
  }

  Future<void> refreshNotifications() async {
    isLoading.value = true;
    hasError.value = false;

    try {
      await _notificationService.fetchNotifications(refresh: true);
    } catch (e) {
      hasError.value = true;
      print('Error refreshing notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreNotifications() async {
    if (isLoading.value) return;

    try {
      await _notificationService.fetchNotifications();
    } catch (e) {
      print('Error loading more notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
    } catch (e) {
      print('Error marking notification as read: $e');
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
      print('Error marking all notifications as read: $e');
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
