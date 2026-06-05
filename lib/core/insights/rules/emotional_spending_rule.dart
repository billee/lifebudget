import '../insight_model.dart';
import '../insight_rule.dart';

/// Detects correlation between negative emotions (slip-ups/journal) and spending spikes.
class EmotionalSpendingRule extends InsightRule {
  @override
  List<Insight> analyze(InsightContext ctx) {
    if (ctx.slipUps.isEmpty && ctx.journalEntries.isEmpty) return [];
    if (ctx.totalIncome <= 0) return [];

    final insights = <Insight>[];

    // Build a set of "bad mood" dates from slip-ups and journal entries
    final badMoodDates = <DateTime>{};
    for (final slip in ctx.slipUps) {
      if (slip.mood == 'stressed' || slip.mood == 'guilty') {
        badMoodDates.add(_dateOnly(slip.date));
      }
    }
    for (final entry in ctx.journalEntries) {
      if (entry.mood == 'stressed') {
        badMoodDates.add(_dateOnly(entry.date));
      }
    }

    if (badMoodDates.isEmpty) return [];

    // Calculate spending on bad-mood days vs all days
    double badDaySpending = 0;
    int badDayCount = 0;
    double goodDaySpending = 0;
    int goodDayCount = 0;

    // Group transactions by date
    final spendingByDate = <DateTime, double>{};
    for (final t in ctx.transactions) {
      if (t.type == 'expense') {
        final day = _dateOnly(t.date);
        spendingByDate[day] = (spendingByDate[day] ?? 0) + t.amount;
      }
    }

    // Compare bad days vs good days
    for (final entry in spendingByDate.entries) {
      if (badMoodDates.contains(entry.key)) {
        badDaySpending += entry.value;
        badDayCount++;
      } else {
        goodDaySpending += entry.value;
        goodDayCount++;
      }
    }

    // Also count bad-mood days with zero spending
    for (final d in badMoodDates) {
      if (!spendingByDate.containsKey(d)) {
        badDayCount++;
      }
    }

    if (badDayCount == 0 || goodDayCount == 0) return [];

    final avgBadDay = badDaySpending / badDayCount;
    final avgGoodDay = goodDaySpending / goodDayCount;

    if (avgGoodDay <= 0) return [];

    final ratio = avgBadDay / avgGoodDay;
    if (ratio > 1.5) {
      insights.add(Insight(
        type: InsightType.tip,
        title: 'Emotional spending detected',
        message:
            'On stressful days you spend ~${_fmt(avgBadDay)}/day on average, vs ~${_fmt(avgGoodDay)}/day on good days — ${(ratio * 100).round() - 100}% more.',
        action:
            'When you feel stressed, try a no-spend walk or journaling before purchasing.',
        metric: '${ratio.toStringAsFixed(1)}x on bad days',
      ));
    }

    return insights;
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  String _fmt(double v) => '\$${v.toStringAsFixed(0)}';
}
