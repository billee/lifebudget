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

    if (!enabled) {
      debugPrint('[NotificationService] Reminder disabled, cancelled.');
      return;
    }

    debugPrint(
        '[NotificationService] Scheduling reminder for ${time.hour}:${time.minute}');

    final androidDetails = AndroidNotificationDetails(
      'daily_reminder_v2',
      'Daily Check-in',
      channelDescription: 'A gentle reminder to check your budget',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
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

    debugPrint('[NotificationService] Next notification at: $scheduledDate');

    // Convert to TZDateTime using local timezone
    final tz.TZDateTime tzScheduled =
        tz.TZDateTime.from(scheduledDate, tz.local);

    debugPrint('[NotificationService] TZDateTime: $tzScheduled');

    await _plugin.zonedSchedule(
      0,
      'LifeBudget',
      'Hey! How did today go money‑wise? Just 30 seconds.',
      tzScheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[NotificationService] Reminder scheduled successfully!');
  }

  /// Cancel the daily reminder
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(0);
  }

  /// Show a test notification immediately
  Future<void> showTestNotification() async {
    debugPrint('[NotificationService] Showing test notification...');

    final androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Daily Check-in',
      channelDescription: 'A gentle reminder to check your budget',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _plugin.show(
      999,
      'LifeBudget Test',
      'This is a test notification. If you see this, notifications are working!',
      details,
    );

    debugPrint('[NotificationService] Test notification shown!');
  }
}
