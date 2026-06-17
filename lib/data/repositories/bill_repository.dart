import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/bill_model.dart';
import 'package:sqflite/sqflite.dart';

class BillRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert a bill
  Future<int> insertBill(BillModel bill) async {
    final db = await _dbHelper.database;
    return await db.insert(
      DatabaseConstants.billsTable,
      bill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all bills
  Future<List<BillModel>> getAllBills() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.billsTable,
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => BillModel.fromMap(map)).toList();
  }

  // Get unpaid bills
  Future<List<BillModel>> getUnpaidBills() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.billsTable,
      where: 'isPaid = ?',
      whereArgs: [0],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => BillModel.fromMap(map)).toList();
  }

  // Get bills due within X days
  Future<List<BillModel>> getBillsDueWithinDays(int days) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final futureDate = now.add(Duration(days: days));

    final maps = await db.query(
      DatabaseConstants.billsTable,
      where: 'isPaid = ? AND dueDate >= ? AND dueDate <= ?',
      whereArgs: [
        0,
        now.toIso8601String(),
        futureDate.toIso8601String(),
      ],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => BillModel.fromMap(map)).toList();
  }

  // Get overdue bills
  Future<List<BillModel>> getOverdueBills() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();

    final maps = await db.query(
      DatabaseConstants.billsTable,
      where: 'isPaid = ? AND dueDate < ?',
      whereArgs: [0, now.toIso8601String()],
      orderBy: 'dueDate ASC',
    );
    return maps.map((map) => BillModel.fromMap(map)).toList();
  }

  // Update a bill
  Future<void> updateBill(BillModel bill) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.billsTable,
      bill.toMap(),
      where: 'id = ?',
      whereArgs: [bill.id],
    );
  }

  // Mark bill as paid
  Future<void> markAsPaid(int billId) async {
    final db = await _dbHelper.database;
    await db.update(
      DatabaseConstants.billsTable,
      {
        'isPaid': 1,
        'paidDate': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [billId],
    );
  }

  // Delete a bill
  Future<void> deleteBill(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.billsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all bills for a category
  Future<void> deleteBillsByCategory(String category) async {
    final db = await _dbHelper.database;
    await db.delete(
      DatabaseConstants.billsTable,
      where: 'category = ?',
      whereArgs: [category],
    );
  }
}
