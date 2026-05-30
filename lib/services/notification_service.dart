import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import '../models/task.dart';

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request permissions for Android 13+ and iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    
    // For iOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    
    // For macOS
    await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> schedule(Task task, String topicName) async {
    if (task.scheduledAt == null || task.isDone) return;
    
    final scheduledDate = TZDateTime.from(task.scheduledAt!, local);
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      task.id.hashCode,
      task.title,
      'Topic: $topicName',
      scheduledDate,
      _buildDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(String taskId) =>
      _plugin.cancel(taskId.hashCode);

  NotificationDetails _buildDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          'focusdo_alarms',
          'FocusDo Alarms',
          channelDescription: 'Alarm notifications for tasks',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
}
