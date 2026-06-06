import 'insight_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/budget_plan_model.dart';
import '../../data/models/expected_expense_model.dart';
import '../../data/models/goal_model.dart';
import '../../data/models/slip_up_model.dart';
import '../../data/models/journal_entry_model.dart';

/// All data a rule might need, pre-fetched by the engine.
class InsightContext {
  final List<TransactionModel> transactions;
  final List<JarAllocation> allocations;
  final List<ExpectedExpense> expectedExpenses;
  final List<Goal> goals;
  final List<SlipUp> slipUps;
  final List<JournalEntry> journalEntries;

  /// Total income this month.
  final double totalIncome;

  /// Spending per jar (lowercased jar name → total), includes expenses + savings.
  final Map<String, double> jarSpent;

  /// Spending per jar for actual expenses only (excludes savings/goal contributions).
  final Map<String, double> expenseOnlySpent;

  /// Days elapsed in the current month (1-based).
  final int daysElapsed;

  /// Total days in the current month.
  final int daysInMonth;

  const InsightContext({
    required this.transactions,
    required this.allocations,
    required this.expectedExpenses,
    required this.goals,
    required this.slipUps,
    required this.journalEntries,
    required this.totalIncome,
    required this.jarSpent,
    required this.expenseOnlySpent,
    required this.daysElapsed,
    required this.daysInMonth,
  });
}

/// Base class for every rule.
abstract class InsightRule {
  List<Insight> analyze(InsightContext ctx);
}
