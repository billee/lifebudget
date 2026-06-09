import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'app.dart';
import 'services/notification_service.dart';
import 'services/goal_auto_saver.dart';
import 'data/repositories/expected_expense_repository.dart'; // added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.local);
  await NotificationService.instance.init();
  await MobileAds.instance.initialize();
  await GoalAutoSaver.processDaily();

  // One‑time cleanup: remove duplicate "Safely Spend" entries
  final expectedExpenseRepo = ExpectedExpenseRepository();
  await expectedExpenseRepo.deduplicateSafelySpend();

  runApp(const ProviderScope(child: LifeBudgetApp()));
}
