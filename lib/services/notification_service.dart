import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  /// Schedule a daily repeating notification at the given [time] (hour and minute).
  Future<void> scheduleDailyReminder({
    required bool enabled,
    required TimeOfDay time,
  }) async {
    // Cancel any existing daily notification (ID 0)
    await _plugin.cancel(0);

    if (!enabled) return;

    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Check-in',
      channelDescription: 'A gentle reminder to check your budget',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    // Calculate the next occurrence of the chosen time
    final now = DateTime.now();
    var scheduledDate =
        DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Convert to TZDateTime using local timezone
    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledDate, tz.local);

    await _plugin.zonedSchedule(
      0,
      'LifeBudget',
      'Hey! How did today go money‑wise? Just 30 seconds.',
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel the daily reminder
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(0);
  }
}
