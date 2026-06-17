import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'database_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('lifebudget.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 8, // <--- version bumped to 8 for debts table
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // transactions table (now includes 'source' column)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.transactionsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colType} TEXT NOT NULL,
        ${DatabaseConstants.colJar} TEXT NOT NULL,
        ${DatabaseConstants.colAmount} REAL NOT NULL,
        ${DatabaseConstants.colDate} TEXT NOT NULL,
        ${DatabaseConstants.colNote} TEXT,
        source TEXT
      )
    ''');

    // jar allocations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.jarAllocationsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colMonth} TEXT NOT NULL,
        ${DatabaseConstants.colJarName} TEXT NOT NULL,
        ${DatabaseConstants.colPercentage} REAL NOT NULL
      )
    ''');

    // expected expenses table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.expectedExpensesTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL
      )
    ''');

    // slip‑ups table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.slipUpsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        amount REAL,
        mood TEXT NOT NULL,
        note TEXT
      )
    ''');

    // archived transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.archivedTransactionsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DatabaseConstants.colType} TEXT NOT NULL,
        ${DatabaseConstants.colJar} TEXT NOT NULL,
        ${DatabaseConstants.colAmount} REAL NOT NULL,
        ${DatabaseConstants.colDate} TEXT NOT NULL,
        ${DatabaseConstants.colNote} TEXT,
        archived_month TEXT NOT NULL
      )
    ''');

    // journal table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.journalTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        mood TEXT NOT NULL,
        went_well TEXT,
        do_differently TEXT
      )
    ''');

    // goals table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.goalsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0,
        emoji TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdDate TEXT NOT NULL
      )
    ''');

    // bills table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.billsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        category TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        isPaid INTEGER NOT NULL DEFAULT 0,
        paidDate TEXT
      )
    ''');

    // debts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.debtsTable} (
        ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        currentBalance REAL NOT NULL,
        interestRate REAL NOT NULL DEFAULT 0,
        minimumPayment REAL NOT NULL,
        dueDate TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migrations from version 4
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.jarAllocationsTable} (
          ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
          ${DatabaseConstants.colMonth} TEXT NOT NULL,
          ${DatabaseConstants.colJarName} TEXT NOT NULL,
          ${DatabaseConstants.colPercentage} REAL NOT NULL
        )
      ''');
    }

    // Migration for version 5: drop old goals table and recreate
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS ${DatabaseConstants.goalsTable}');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.goalsTable} (
          ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL NOT NULL DEFAULT 0,
          emoji TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          createdDate TEXT NOT NULL
        )
      ''');
    }

    // New migration for version 6: add 'source' column to transactions table
    if (oldVersion < 6) {
      try {
        await db.execute(
            'ALTER TABLE ${DatabaseConstants.transactionsTable} ADD COLUMN source TEXT');
      } catch (e) {
        // Column may already exist – ignore error
      }
    }

    // Migration for version 7: bills table
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.billsTable} (
          ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          dueDate TEXT NOT NULL,
          category TEXT NOT NULL,
          isRecurring INTEGER NOT NULL DEFAULT 0,
          isPaid INTEGER NOT NULL DEFAULT 0,
          paidDate TEXT
        )
      ''');
    }

    // Migration for version 8: debts table
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.debtsTable} (
          ${DatabaseConstants.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          totalAmount REAL NOT NULL,
          currentBalance REAL NOT NULL,
          interestRate REAL NOT NULL DEFAULT 0,
          minimumPayment REAL NOT NULL,
          dueDate TEXT NOT NULL,
          notes TEXT
        )
      ''');
    }
  }
}
