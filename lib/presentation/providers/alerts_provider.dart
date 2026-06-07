import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/alerts/alert_model.dart';
import '../../core/alerts/alert_generator.dart';
import 'transaction_provider.dart';
import 'budget_provider.dart';
import 'expected_expenses_provider.dart';
import 'goal_provider.dart';
import 'slip_up_provider.dart';

String _currentMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// Provides the list of budget alerts for the notification center.
final alertsProvider = FutureProvider<List<BudgetAlert>>((ref) async {
  final transactions = await ref.watch(allTransactionsProvider.future);
  final allocationsList = await ref.watch(jarAllocationsProvider.future);
  final goals = await ref.watch(goalsProvider.future);

  // Convert allocations to map: jarName → percentage
  final Map<String, double> allocations = {};
  for (final a in allocationsList) {
    allocations[a.jarName.toLowerCase()] = a.percentage;
  }

  // Slip-ups for current month
  final slipUpRepo = ref.watch(slipUpRepositoryProvider);
  final slipUps = await slipUpRepo.getForMonth(_currentMonth());

  // Compute income and jarSpent from current month transactions
  final now = DateTime.now();
  final firstDay = DateTime(now.year, now.month, 1);

  double totalIncome = 0;
  final Map<String, double> jarSpent = {};

  for (final t in transactions) {
    if (t.date.isBefore(firstDay)) continue;
    if (t.type == 'income') {
      totalIncome += t.amount;
    } else {
      var jar = t.jar.toLowerCase();
      if (jar.startsWith('goal_')) jar = jar.substring(5);
      jarSpent[jar] = (jarSpent[jar] ?? 0) + t.amount;
    }
  }

  // Days since last expense log
  final expenseDates = transactions
      .where((t) => t.type == 'expense')
      .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
      .toSet();

  int daysSinceLastLog = 0;
  if (expenseDates.isEmpty) {
    daysSinceLastLog = now.difference(firstDay).inDays + 1;
  } else {
    final lastLogDate = expenseDates.reduce((a, b) => a.isAfter(b) ? a : b);
    daysSinceLastLog =
        DateTime(now.year, now.month, now.day).difference(lastLogDate).inDays;
  }

  return AlertGenerator.generate(
    transactions: transactions,
    jarSpent: jarSpent,
    allocations: allocations,
    totalIncome: totalIncome,
    goals: goals,
    slipUps: slipUps,
    daysSinceLastLog: daysSinceLastLog,
  );
});

/// Provides just the unread alert count (for the badge).
/// Returns 0 if the user has viewed notifications since the last change.
final alertCountProvider = FutureProvider<int>((ref) async {
  final alerts = await ref.watch(alertsProvider.future);
  final prefs = await SharedPreferences.getInstance();
  final lastViewedMs = prefs.getInt('notifications_last_viewed') ?? 0;
  final lastViewed = DateTime.fromMillisecondsSinceEpoch(lastViewedMs);

  // Count alerts that are newer than the last viewed time
  return alerts.where((a) => a.timestamp.isAfter(lastViewed)).length;
});

/// Mark all notifications as viewed (clears the badge).
Future<void> markNotificationsViewed() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
      'notifications_last_viewed', DateTime.now().millisecondsSinceEpoch);
}
