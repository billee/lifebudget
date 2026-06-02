import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/budget_plan_model.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Returns the jar percentage allocations for a specific month.
  /// If none exist, creates a default set (including a Savings jar) and returns it.
  Future<List<JarAllocation>> getJarAllocations(String month) async {
    final db = await _dbHelper.database;

    var maps = await db.query(
      DatabaseConstants.jarAllocationsTable,
      where: '${DatabaseConstants.colMonth} = ?',
      whereArgs: [month],
    );

    if (maps.isEmpty) {
      // No allocation yet for this month – create default percentages
      final defaults = _defaultAllocations(month);
      for (final alloc in defaults) {
        await db.insert(DatabaseConstants.jarAllocationsTable, alloc.toMap());
      }
      return defaults;
    }

    return maps.map((m) => JarAllocation.fromMap(m)).toList();
  }

  /// Saves (replaces) the jar percentage allocations for a given month.
  Future<void> saveJarAllocations(
      String month, List<JarAllocation> allocations) async {
    final db = await _dbHelper.database;

    await db.delete(
      DatabaseConstants.jarAllocationsTable,
      where: '${DatabaseConstants.colMonth} = ?',
      whereArgs: [month],
    );

    for (final alloc in allocations) {
      await db.insert(DatabaseConstants.jarAllocationsTable, alloc.toMap());
    }
  }

  List<JarAllocation> _defaultAllocations(String month) {
    // Default jars with percentages (must sum to 100)
    return [
      JarAllocation(month: month, jarName: 'rent', percentage: 30),
      JarAllocation(month: month, jarName: 'food', percentage: 25),
      JarAllocation(month: month, jarName: 'transport', percentage: 10),
      JarAllocation(month: month, jarName: 'health', percentage: 5),
      JarAllocation(month: month, jarName: 'fun', percentage: 10),
      JarAllocation(month: month, jarName: 'savings', percentage: 20),
    ];
  }
}
