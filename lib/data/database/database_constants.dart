class DatabaseConstants {
  // Tables
  static const String transactionsTable = 'transactions';
  static const String jarAllocationsTable = 'jar_allocations';
  static const String expectedExpensesTable = 'expected_expenses';
  static const String slipUpsTable = 'slip_ups';
  static const String archivedTransactionsTable = 'archived_transactions';
  static const String journalTable = 'journal_entries';
  static const String goalsTable = 'goals';
  static const String colDailyAmount = 'daily_amount';

  // Common columns
  static const String colId = 'id';
  static const String colMonth = 'month'; // e.g., '2026-06'

  // jar_allocations columns
  static const String colJarName = 'jar_name';
  static const String colPercentage = 'percentage'; // 0.0 - 100.0

  // transactions columns (unchanged)
  static const String colType = 'type'; // 'expense' or 'income'
  static const String colJar =
      'jar'; // jar name for expense, 'income' for income
  static const String colAmount = 'amount';
  static const String colDate = 'date';
  static const String colNote = 'note';
}
