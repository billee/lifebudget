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

  /// Schedule a bill reminder notification
  Future<void> scheduleBillReminder({
    required int billId,
    required String title,
    required double amount,
    required DateTime dueDate,
    int daysBefore = 3, // Default: 3 days before due date
  }) async {
    // Cancel any existing reminder for this bill
    await cancelBillReminder(billId);

    final reminderDate = dueDate.subtract(Duration(days: daysBefore));

    // Don't schedule if the reminder date has already passed
    if (reminderDate.isBefore(DateTime.now())) {
      debugPrint(
          '[NotificationService] Bill reminder date already passed for: $title');
      return;
    }

    debugPrint(
        '[NotificationService] Scheduling bill reminder for $title on $reminderDate');

    final androidDetails = AndroidNotificationDetails(
      'bill_reminders',
      'Bill Reminders',
      channelDescription: 'Reminders for upcoming bills',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    final tz.TZDateTime tzReminder = tz.TZDateTime.from(reminderDate, tz.local);

    await _plugin.zonedSchedule(
      billId + 1000, // Offset to avoid conflicts with other notifications
      'Bill Due: $title',
      '₱${amount.toStringAsFixed(0)} due in $daysBefore days!',
      tzReminder,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[NotificationService] Bill reminder scheduled for: $title');
  }

  /// Cancel a specific bill reminder
  Future<void> cancelBillReminder(int billId) async {
    await _plugin.cancel(billId + 1000);
  }

  /// Cancel all bill reminders
  Future<void> cancelAllBillReminders() async {
    // Get all pending notifications and cancel bill reminders
    // Note: This is a simplified version. In production, you might want to track
    // bill IDs separately or use a more sophisticated cancellation strategy.
    final pendingNotifications = await _plugin.pendingNotificationRequests();
    for (final notification in pendingNotifications) {
      if (notification.id >= 1000) {
        // Bill reminders use IDs >= 1000
        await _plugin.cancel(notification.id);
      }
    }
  }
}
