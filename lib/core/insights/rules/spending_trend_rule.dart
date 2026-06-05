import '../insight_model.dart';
import '../insight_rule.dart';

/// Compares this month's daily spending rate to last month's archived data.
/// If no archived data, projects whether current pace will exceed income.
class SpendingTrendRule extends InsightRule {
  /// Last month's jar summaries (may be empty if no archive exists).
  final Map<String, double> lastMonthJarSpent;

  SpendingTrendRule({this.lastMonthJarSpent = const {}});

  @override
  List<Insight> analyze(InsightContext ctx) {
    if (ctx.totalIncome <= 0 || ctx.daysElapsed <= 0) return [];

    final insights = <Insight>[];

    // Total current spending
    final totalSpent = ctx.jarSpent.values.fold<double>(0, (a, b) => a + b);

    if (lastMonthJarSpent.isNotEmpty) {
      // Compare per-jar: which jars are trending up vs last month?
      final lastTotal =
          lastMonthJarSpent.values.fold<double>(0, (a, b) => a + b);

      // Projected total based on current pace
      final projectedTotal = (totalSpent / ctx.daysElapsed) * ctx.daysInMonth;

      if (lastTotal > 0 && projectedTotal > lastTotal * 1.15) {
        final increasePct =
            (((projectedTotal - lastTotal) / lastTotal) * 100).round();
        insights.add(Insight(
          type: InsightType.warning,
          title: 'Spending is trending up',
          message:
              'At your current pace, you\'ll spend ~\$${projectedTotal.toStringAsFixed(0)} this month — $increasePct% more than last month (\$${lastTotal.toStringAsFixed(0)}).',
          action:
              'Review which jars are driving the increase and cut back where possible.',
          metric: '+$increasePct%',
        ));
      }
    } else {
      // No archive: just project and warn if pace exceeds income
      final projectedTotal = (totalSpent / ctx.daysElapsed) * ctx.daysInMonth;
      if (projectedTotal > ctx.totalIncome * 0.9) {
        final pct = (projectedTotal / ctx.totalIncome * 100).round();
        insights.add(Insight(
          type: pct > 100 ? InsightType.warning : InsightType.tip,
          title: pct > 100 ? 'On track to overspend' : 'Spending pace is tight',
          message: pct > 100
              ? 'At your current daily rate, you\'ll spend ~\$${projectedTotal.toStringAsFixed(0)} — more than your \$${ctx.totalIncome.toStringAsFixed(0)} income.'
              : 'You\'re projected to use $pct% of your income by month end.',
          action: 'Slow down daily spending or look for jars you can trim.',
          metric: '\$${projectedTotal.toStringAsFixed(0)} projected',
        ));
      }
    }

    return insights;
  }
}
