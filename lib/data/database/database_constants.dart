class DatabaseConstants {
  // existing tables
  static const String transactionsTable = 'transactions';
  static const String monthlyBudgetTable =
      'budget_plans'; // renamed for clarity

  // new tables
  static const String jarAllocationsTable = 'jar_allocations';

  // common columns
  static const String colId = 'id';
  static const String colMonth = 'month'; // e.g., '2026-06'

  // budget_plans columns
  static const String colTotalBudget = 'total_budget';

  // jar_allocations columns
  static const String colJarName = 'jar_name';
  static const String colAllocatedAmount = 'allocated_amount';

  // transactions columns (unchanged)
  static const String colType = 'type';
  static const String colJar = 'jar';
  static const String colAmount = 'amount';
  static const String colDate = 'date';
  static const String colNote = 'note';
}
