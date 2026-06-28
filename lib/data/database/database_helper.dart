import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Table names (local constants)
  static const String transactionsTable = 'transactions';
  static const String jarAllocationsTable = 'jar_allocations';
  static const String expectedExpensesTable = 'expected_expenses';
  static const String slipUpsTable = 'slip_ups';
  static const String archivedTransactionsTable = 'archived_transactions';
  static const String journalTable = 'journal_entries';
  static const String goalsTable = 'goals';
  static const String billsTable = 'bills';
  static const String debtsTable = 'debts';

  // Common column names
  static const String colId = 'id';
  static const String colMonth = 'month';
  static const String colJarName = 'jar_name';
  static const String colPercentage = 'percentage';
  static const String colType = 'type';
  static const String colJar = 'jar';
  static const String colAmount = 'amount';
  static const String colDate = 'date';
  static const String colNote = 'note';
  static const String colDueDate = 'due_date'; // NEW

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
      version: 9, // <--- version bumped to 9 for due_date
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $transactionsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colType TEXT NOT NULL,
        $colJar TEXT NOT NULL,
        $colAmount REAL NOT NULL,
        $colDate TEXT NOT NULL,
        $colNote TEXT,
        source TEXT
      )
    ''');

    // jar allocations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $jarAllocationsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colMonth TEXT NOT NULL,
        $colJarName TEXT NOT NULL,
        $colPercentage REAL NOT NULL
      )
    ''');

    // expected expenses table – now with due_date
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $expectedExpensesTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        frequency TEXT NOT NULL,
        $colAmount REAL NOT NULL,
        $colMonth TEXT NOT NULL,
        $colDueDate TEXT
      )
    ''');

    // slip‑ups table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $slipUpsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colDate TEXT NOT NULL,
        $colAmount REAL,
        mood TEXT NOT NULL,
        $colNote TEXT
      )
    ''');

    // archived transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $archivedTransactionsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colType TEXT NOT NULL,
        $colJar TEXT NOT NULL,
        $colAmount REAL NOT NULL,
        $colDate TEXT NOT NULL,
        $colNote TEXT,
        archived_month TEXT NOT NULL
      )
    ''');

    // journal table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $journalTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        $colDate TEXT NOT NULL,
        mood TEXT NOT NULL,
        went_well TEXT,
        do_differently TEXT
      )
    ''');

    // goals table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $goalsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
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
      CREATE TABLE IF NOT EXISTS $billsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        $colAmount REAL NOT NULL,
        dueDate TEXT NOT NULL,
        category TEXT NOT NULL,
        isRecurring INTEGER NOT NULL DEFAULT 0,
        isPaid INTEGER NOT NULL DEFAULT 0,
        paidDate TEXT
      )
    ''');

    // debts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $debtsTable (
        $colId INTEGER PRIMARY KEY AUTOINCREMENT,
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
        CREATE TABLE IF NOT EXISTS $jarAllocationsTable (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          $colMonth TEXT NOT NULL,
          $colJarName TEXT NOT NULL,
          $colPercentage REAL NOT NULL
        )
      ''');
    }

    // Version 5: drop old goals table and recreate
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS $goalsTable');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $goalsTable (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL NOT NULL DEFAULT 0,
          emoji TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          createdDate TEXT NOT NULL
        )
      ''');
    }

    // Version 6: add 'source' column to transactions
    if (oldVersion < 6) {
      try {
        await db
            .execute('ALTER TABLE $transactionsTable ADD COLUMN source TEXT');
      } catch (e) {/* column may already exist */}
    }

    // Version 7: bills table
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $billsTable (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          $colAmount REAL NOT NULL,
          dueDate TEXT NOT NULL,
          category TEXT NOT NULL,
          isRecurring INTEGER NOT NULL DEFAULT 0,
          isPaid INTEGER NOT NULL DEFAULT 0,
          paidDate TEXT
        )
      ''');
    }

    // Version 8: debts table
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $debtsTable (
          $colId INTEGER PRIMARY KEY AUTOINCREMENT,
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

    // Version 9: add due_date to expected_expenses
    if (oldVersion < 9) {
      try {
        await db.execute(
            'ALTER TABLE $expectedExpensesTable ADD COLUMN $colDueDate TEXT');
      } catch (e) {
        // column may already exist
      }
    }
  }
}
