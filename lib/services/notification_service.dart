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
          'focusdo_channel',
          'FocusDo Reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
}
