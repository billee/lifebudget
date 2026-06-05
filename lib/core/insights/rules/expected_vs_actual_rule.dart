import '../insight_model.dart';
import '../insight_rule.dart';

/// Compares expected (planned) expenses to actual spending per jar.
class ExpectedVsActualRule extends InsightRule {
  @override
  List<Insight> analyze(InsightContext ctx) {
    if (ctx.expectedExpenses.isEmpty || ctx.daysElapsed <= 0) return [];

    final insights = <Insight>[];

    for (final exp in ctx.expectedExpenses) {
      final jarKey = exp.title.toLowerCase();
      final actualSpent = ctx.jarSpent[jarKey] ?? 0;

      // Calculate expected amount for elapsed days
      double expectedSoFar;
      switch (exp.frequency) {
        case 'daily':
          expectedSoFar = exp.amount * ctx.daysElapsed;
          break;
        case 'weekly':
          expectedSoFar = (exp.amount / 7) * ctx.daysElapsed;
          break;
        case 'monthly':
          // For monthly, compare proportionally
          expectedSoFar = exp.amount * (ctx.daysElapsed / ctx.daysInMonth);
          break;
        default:
          continue;
      }

      if (expectedSoFar <= 0) continue;

      final ratio = actualSpent / expectedSoFar;

      // Significantly over expected (>150%)
      if (ratio > 1.5) {
        final overPct = ((ratio - 1) * 100).round();
        insights.add(Insight(
          type: InsightType.warning,
          title: '${exp.title} spending above plan',
          message:
              'You\'ve spent \$${actualSpent.toStringAsFixed(0)} on ${exp.title}, which is $overPct% above the expected \$${expectedSoFar.toStringAsFixed(0)} for this point in the month.',
          action:
              'Review recent ${exp.title} transactions. Look for subscriptions or habits you can trim.',
          metric: '+$overPct% vs plan',
          jarName: exp.title,
        ));
      }
      // Significantly under expected (<40%) — could mean unmet needs or great discipline
      else if (ratio < 0.4 && ctx.daysElapsed >= 7) {
        insights.add(Insight(
          type: InsightType.achievement,
          title: '${exp.title} well under budget',
          message:
              'You\'ve only spent \$${actualSpent.toStringAsFixed(0)} on ${exp.title} vs the expected \$${expectedSoFar.toStringAsFixed(0)} — saving \$${(expectedSoFar - actualSpent).toStringAsFixed(0)}.',
          action:
              'If this is intentional discipline, great! If not, check you\'re not skipping important ${exp.title} needs.',
          metric: '\$${(expectedSoFar - actualSpent).toStringAsFixed(0)} saved',
          jarName: exp.title,
        ));
      }
    }

    return insights;
  }
}
