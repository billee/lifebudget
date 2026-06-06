import '../insight_model.dart';
import '../insight_rule.dart';

/// Projects spending based on expense frequency:
/// - Monthly expenses: use actual amount (fixed for the month)
/// - Daily/weekly expenses: (spent / daysElapsed) × daysInMonth
class SpendingTrendRule extends InsightRule {
  final Map<String, double> lastMonthJarSpent;

  SpendingTrendRule({this.lastMonthJarSpent = const {}});

  @override
  List<Insight> analyze(InsightContext ctx) {
    if (ctx.totalIncome <= 0 || ctx.daysElapsed <= 0) return [];

    final insights = <Insight>[];

    // Build sets of monthly vs daily/weekly jars from expected expenses
    final monthlyJars = <String>{};
    for (final exp in ctx.expectedExpenses) {
      if (exp.frequency == 'monthly') {
        monthlyJars.add(exp.title.toLowerCase());
      }
    }

    // Split spending into monthly (fixed) and daily/weekly (variable)
    double monthlySpent = 0;
    double dailySpent = 0;

    for (final entry in ctx.jarSpent.entries) {
      if (monthlyJars.contains(entry.key)) {
        monthlySpent += entry.value;
      } else {
        dailySpent += entry.value;
      }
    }

    // Projection: monthly actual + daily rate × full month
    final dailyRate = dailySpent / ctx.daysElapsed;
    final projectedDaily = dailyRate * ctx.daysInMonth;
    final projectedTotal = monthlySpent + projectedDaily;

    if (lastMonthJarSpent.isNotEmpty) {
      // Compare with last month
      final lastTotal =
          lastMonthJarSpent.values.fold<double>(0, (a, b) => a + b);

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
      // No archive: warn if projection exceeds income
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
