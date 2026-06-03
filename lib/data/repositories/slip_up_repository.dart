import '../database/database_helper.dart';
import '../database/database_constants.dart';
import '../models/slip_up_model.dart';

class SlipUpRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> insert(SlipUp slipUp) async {
    final db = await _dbHelper.database;
    return await db.insert(DatabaseConstants.slipUpsTable, slipUp.toMap());
  }

  Future<List<SlipUp>> getRecent({int limit = 5}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      DatabaseConstants.slipUpsTable,
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => SlipUp.fromMap(m)).toList();
  }
}
