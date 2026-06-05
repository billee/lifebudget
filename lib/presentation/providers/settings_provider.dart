import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  final bool enabled;
  final TimeOfDay time;

  const ReminderSettings({required this.enabled, required this.time});

  ReminderSettings copyWith({bool? enabled, TimeOfDay? time}) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }
}

final reminderSettingsProvider =
    StateNotifierProvider<ReminderSettingsNotifier, ReminderSettings>((ref) {
  return ReminderSettingsNotifier();
});

class ReminderSettingsNotifier extends StateNotifier<ReminderSettings> {
  ReminderSettingsNotifier()
      : super(const ReminderSettings(
            enabled: false, time: TimeOfDay(hour: 20, minute: 0))) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('reminder_enabled') ?? false;
    final hour = prefs.getInt('reminder_hour') ?? 20;
    final minute = prefs.getInt('reminder_minute') ?? 0;
    state = ReminderSettings(
      enabled: enabled,
      time: TimeOfDay(hour: hour, minute: minute),
    );
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', enabled);
    state = state.copyWith(enabled: enabled);
  }

  Future<void> setTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_hour', time.hour);
    await prefs.setInt('reminder_minute', time.minute);
    state = state.copyWith(time: time);
  }
}
