import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/milestone_checker.dart';
import 'transaction_provider.dart';
import 'expected_expenses_provider.dart';
import 'journal_provider.dart';

final shownMilestonesProvider = FutureProvider<Set<String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final shown = prefs.getStringList('shown_milestones') ?? [];
  return shown.toSet();
});

final newMilestoneProvider = FutureProvider<Milestone?>((ref) async {
  final shown = await ref.watch(shownMilestonesProvider.future);
  final allTxns = await ref.watch(allTransactionsProvider.future);
  final expectedExpenses = await ref.watch(expectedExpensesProvider.future);
  final journalEntries = await ref.watch(journalEntriesProvider.future);

  // Compute stats
  int totalIncome = 0;
  int totalExpenses = 0;
  Set<DateTime> daysWithActivity = {};
  for (final t in allTxns) {
    if (t.type == 'income')
      totalIncome++;
    else
      totalExpenses++;
    daysWithActivity.add(DateTime(t.date.year, t.date.month, t.date.day));
  }
  final int daysTracking = daysWithActivity.length;
  final bool hasJournalEntry = journalEntries.isNotEmpty;
  final bool hasSavingsJar =
      expectedExpenses.any((e) => e.title.toLowerCase().contains('sav'));

  final available = getAvailableMilestones(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    daysTracking: daysTracking,
    hasJournalEntry: hasJournalEntry,
    hasSavingsJar: hasSavingsJar,
    alreadyShownIds: shown,
  );

  if (available.isEmpty) return null;
  return available.first; // show one at a time
});
