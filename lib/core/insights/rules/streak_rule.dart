import '../insight_model.dart';
import '../insight_rule.dart';

/// Positive reinforcement: detects consecutive days with zero discretionary spending.
class StreakRule extends InsightRule {
  /// Jars considered discretionary.
  static const _discretionaryJars = {'fun', 'food', 'entertainment'};

  @override
  List<Insight> analyze(InsightContext ctx) {
    if (ctx.transactions.isEmpty) return [];

    // Build a set of dates with discretionary spending
    final spendDates = <DateTime>{};
    for (final t in ctx.transactions) {
      if (t.type == 'expense' &&
          _discretionaryJars.contains(t.jar.toLowerCase())) {
        spendDates.add(_dateOnly(t.date));
      }
    }

    // Count consecutive no-spend days going back from today
    final today = _dateOnly(DateTime.now());
    int streak = 0;
    var checkDate =
        today.subtract(const Duration(days: 1)); // start from yesterday

    while (!spendDates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (streak > 60) break; // cap
    }

    final insights = <Insight>[];

    if (streak >= 7) {
      insights.add(Insight(
        type: InsightType.achievement,
        title: '$streak-day no-spend streak!',
        message:
            'You haven\'t made any discretionary purchases (fun/food) in $streak consecutive days.',
        action:
            'Incredible discipline! Reward yourself with something small from your fun jar.',
        metric: '$streak days',
      ));
    } else if (streak >= 3) {
      insights.add(Insight(
        type: InsightType.achievement,
        title: '$streak-day no-spend streak',
        message:
            'No discretionary spending in $streak days. You\'re building great habits.',
        action: 'Keep this momentum going!',
        metric: '$streak days',
      ));
    }

    return insights;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
