import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification/notification_model.dart';
import '../../core/utils/logger_utils.dart';

class NotificationRepository {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;
  static const String _channelId = 'budget_tracker_channel';
  static const String _channelName = 'Budget Tracker Notifications';
  static const String _channelDescription =
      'Notifications for budget and expense tracking';

  NotificationRepository()
      : _notificationsPlugin = FlutterLocalNotificationsPlugin() {
    _initializeNotifications();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  Future<void> showNotification(NotificationModel notification) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: notification.payload,
    );
  }

  Future<void> scheduleNotification(
    NotificationModel notification,
    DateTime scheduledDate,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      notification.id.hashCode,
      notification.title,
      notification.body,
      _convertToTZDateTime(scheduledDate),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: notification.payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    if (response.payload != null) {
      LoggerUtils.info('Notification tapped with payload: ${response.payload}');
      // Implement navigation based on payload type
      // This will be implemented when navigation service is ready
      // See: https://github.com/your-org/budget-tracker/issues/XX
    }
  }

  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.getLocation('UTC');
    return tz.TZDateTime.from(dateTime, location);
  }
}
