import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/goal_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/models/transaction_model.dart';

/// Automatically creates daily savings transactions for active goals.
/// Called once per day on app startup.
class GoalAutoSaver {
  static const String _lastRunKey = 'goal_auto_saver_last_date';

  /// Process daily goal savings. Only runs once per day.
  static Future<void> processDaily() async {
    // final prefs = await SharedPreferences.getInstance();
    // final lastRun = prefs.getString(_lastRunKey);
    // final today = DateTime.now();
    // final todayStr = '${today.year}-${today.month}-${today.day}';

    // // Already processed today — skip
    // if (lastRun == todayStr) return;

    // final goalRepo = GoalRepository();
    // final txnRepo = TransactionRepository();

    // final goals = await goalRepo.getAll();
    // final now = DateTime.now();

    // for (final goal in goals) {
    //   // Skip completed goals or goals with no daily amount
    //   if (goal.isCompleted || goal.dailyAmount <= 0) continue;

    //   // Check if this goal already has a transaction today
    //   final existing =
    //       await txnRepo.getTransactionsByJar(goal.title.toLowerCase());
    //   final alreadySavedToday = existing.any((t) {
    //     return t.type == 'savings' &&
    //         t.date.year == today.year &&
    //         t.date.month == today.month &&
    //         t.date.day == today.day;
    //   });

    //   if (alreadySavedToday) continue;

    //   // Calculate how much to save (don't exceed target)
    //   final remaining = goal.targetAmount - goal.currentAmount;
    //   final amountToSave =
    //       remaining < goal.dailyAmount ? remaining : goal.dailyAmount;

    //   if (amountToSave <= 0) continue;

    //   // Create savings transaction
    //   final transaction = TransactionModel(
    //     type: 'savings',
    //     jar: goal.title.toLowerCase(),
    //     amount: amountToSave,
    //     date: DateTime(now.year, now.month, now.day),
    //     note: 'Auto-saved for ${goal.emoji} ${goal.title}',
    //   );
    //   await txnRepo.insertTransaction(transaction);

    //   // Update goal progress
    //   final newAmount = goal.currentAmount + amountToSave;
    //   final isComplete = newAmount >= goal.targetAmount;

    //   final updatedGoal = goal.copyWith(
    //     currentAmount: newAmount,
    //     isCompleted: isComplete,
    //   );
    //   await goalRepo.update(updatedGoal);
    // }

    // // Mark today as processed
    // await prefs.setString(_lastRunKey, todayStr);

    return;
  }
}
