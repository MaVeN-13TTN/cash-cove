import 'package:get/get.dart';
import '../controllers/notifications_controller.dart';
import '../../../core/services/notifications/notification_service.dart';

class NotificationBinding extends Bindings {
  @override
  void dependencies() {
    // Initialize notification service if not already initialized
    if (!Get.isRegistered<NotificationService>()) {
      Get.put(NotificationService(), permanent: true);
    }

    // Initialize notification controller
    Get.lazyPut<NotificationController>(() => NotificationController());
  }
}
