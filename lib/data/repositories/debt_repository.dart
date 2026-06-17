import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/debt_model.dart';
import 'package:sqflite/sqflite.dart';

class DebtRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a debt
  Future<int> insertDebt(DebtModel debt) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConstants.debtsTable,
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all debts
  Future<List<DebtModel>> getAllDebts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.debtsTable,
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  // Get active debts (not paid off)
  Future<List<DebtModel>> getActiveDebts() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.debtsTable,
      where: 'currentBalance > ?',
      whereArgs: [0],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  // Get total debt balance
  Future<double> getTotalDebtBalance() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT SUM(currentBalance) as total FROM ${DatabaseConstants.debtsTable} WHERE currentBalance > 0',
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  // Get debts due within X days
  Future<List<DebtModel>> getDebtsDueWithinDays(int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final maps = await db.query(
      DatabaseConstants.debtsTable,
      where: 'currentBalance > ? AND dueDate >= ? AND dueDate <= ?',
      whereArgs: [
        0,
        now.toIso8601String(),
        futureDate.toIso8601String(),
      ],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  // Get overdue debts
  Future<List<DebtModel>> getOverdueDebts() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final maps = await db.query(
      DatabaseConstants.debtsTable,
      where: 'currentBalance > ? AND dueDate < ?',
      whereArgs: [0, now.toIso8601String()],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => DebtModel.fromMap(map)).toList();
  }

  // Update a debt
  Future<void> updateDebt(DebtModel debt) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.debtsTable,
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  // Make a payment (reduce balance)
  Future<void> makePayment(int debtId, double amount) async {
    final db = await _dbHelper.database;
    final debt = await getDebtById(debtId);
    if (debt != null) {
      final newBalance =
          (debt.currentBalance - amount).clamp(0, double.infinity);
      await db.update(
        DatabaseConstants.debtsTable,
        {'currentBalance': newBalance},
        where: 'id = ?',
        whereArgs: [debtId],
      );
    }
  }

  // Get a specific debt by ID
  Future<DebtModel?> getDebtById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.debtsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DebtModel.fromMap(maps.first);
  }

  // Delete a debt
  Future<void> deleteDebt(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.debtsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
