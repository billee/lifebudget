import '../insight_model.dart';
import '../insight_rule.dart';

/// Fires when a single jar consumes more than 50% of total spending.
class JarImbalanceRule extends InsightRule {
  @override
  List<Insight> analyze(InsightContext ctx) {
    final totalSpent = ctx.jarSpent.values.fold<double>(0, (a, b) => a + b);
    if (totalSpent <= 0) return [];

    final insights = <Insight>[];

    for (final entry in ctx.jarSpent.entries) {
      final share = entry.value / totalSpent;
      if (share > 0.5) {
        final pct = (share * 100).round();
        // Skip 'savings' — high savings share is good
        if (entry.key == 'savings') {
          insights.add(Insight(
            type: InsightType.achievement,
            title: 'Great savings focus',
            message:
                '$pct% of your spending is going to savings — that\'s excellent discipline!',
            action:
                'Keep it up. Consider if you can increase your savings target.',
            metric: '$pct% to savings',
            jarName: 'savings',
          ));
        } else {
          insights.add(Insight(
            type: InsightType.warning,
            title: '${_capitalize(entry.key)} is dominating your budget',
            message:
                '$pct% of all spending is in "${entry.key}". A balanced budget spreads risk across jars.',
            action:
                'Look for ways to reduce ${entry.key} costs or reallocate some to other jars.',
            metric: '$pct%',
            jarName: entry.key,
          ));
        }
      }
    }

    return insights;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
