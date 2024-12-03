import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/notifications_controller.dart';
import 'widgets/notification_list_item.dart';

class NotificationListView extends GetView<NotificationsController> {
  const NotificationListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Obx(() {
            if (controller.unreadCount > 0) {
              return IconButton(
                icon: const Icon(Icons.done_all),
                onPressed: controller.markAllAsRead,
                tooltip: 'Mark all as read',
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.hasError.value && controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load notifications',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: controller.refreshNotifications,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.refreshNotifications,
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8),
            itemCount: controller.notifications.length + 1,
            itemBuilder: (context, index) {
              if (index == controller.notifications.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Obx(() {
                      if (controller.isLoading.value) {
                        return const CircularProgressIndicator();
                      }
                      return const SizedBox.shrink();
                    }),
                  ),
                );
              }

              final notification = controller.notifications[index];
              return NotificationListItem(
                notification: notification,
                onTap: () => controller.handleNotificationTap(notification),
              );
            },
          ),
        );
      }),
    );
  }
}
