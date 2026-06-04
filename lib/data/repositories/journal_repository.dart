import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/journal_entry_model.dart';

class JournalRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(JournalEntry entry) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseConstants.journalTable, entry.toMap());
  }

  Future<List<JournalEntry>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.journalTable,
      orderBy: 'date DESC',
    );
    return maps.map((m) => JournalEntry.fromMap(m)).toList();
  }

  Future<JournalEntry?> getMostRecent() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.journalTable,
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }
}
