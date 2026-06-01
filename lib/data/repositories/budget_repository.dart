import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/budget_plan_model.dart';

class BudgetRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<BudgetPlan> getOrCreateBudget(String month) async {
    final db = await _dbHelper.database;

    var budgetMaps = await db.query(
      DatabaseConstants.monthlyBudgetTable,
      where: '${DatabaseConstants.colMonth} = ?',
      whereArgs: [month],
    );

    BudgetPlan plan;

    if (budgetMaps.isEmpty) {
      // insert default
      final defaultPlan = BudgetPlan(
        month: month,
        totalBudget: 18000,
        allocations: _defaultAllocations(month),
      );
      final budgetId = await db.insert(
        DatabaseConstants.monthlyBudgetTable,
        defaultPlan.toMap(),
      );
      for (final alloc in defaultPlan.allocations) {
        await db.insert(
          DatabaseConstants.jarAllocationsTable,
          alloc.toMap(),
        );
      }
      plan = defaultPlan.copyWith(id: budgetId);
    } else {
      final budgetMap = budgetMaps.first;
      final allocMaps = await db.query(
        DatabaseConstants.jarAllocationsTable,
        where: '${DatabaseConstants.colMonth} = ?',
        whereArgs: [month],
      );
      final allocations =
          allocMaps.map((m) => JarAllocation.fromMap(m)).toList();
      plan = BudgetPlan.fromMap(budgetMap, allocations: allocations);
    }

    return plan;
  }

  Future<void> updateBudget(BudgetPlan plan) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.monthlyBudgetTable,
      plan.toMap(),
      where: '${DatabaseConstants.colMonth} = ?',
      whereArgs: [plan.month],
    );

    await db.delete(
      DatabaseConstants.jarAllocationsTable,
      where: '${DatabaseConstants.colMonth} = ?',
      whereArgs: [plan.month],
    );
    for (final alloc in plan.allocations) {
      await db.insert(
        DatabaseConstants.jarAllocationsTable,
        alloc.toMap(),
      );
    }
  }

  List<JarAllocation> _defaultAllocations(String month) {
    return [
      JarAllocation(month: month, jarName: 'food', allocatedAmount: 4000),
      JarAllocation(month: month, jarName: 'rent', allocatedAmount: 5000),
      JarAllocation(month: month, jarName: 'transport', allocatedAmount: 1500),
      JarAllocation(month: month, jarName: 'fun', allocatedAmount: 2000),
      JarAllocation(month: month, jarName: 'health', allocatedAmount: 1500),
    ];
  }
}
