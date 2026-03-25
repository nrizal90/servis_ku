import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('servis_ku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_type TEXT NOT NULL,
        name TEXT NOT NULL,
        plate TEXT NOT NULL,
        year INTEGER,
        brand TEXT,
        image_path TEXT,
        stnk_due_date TEXT,
        plat_due_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE service_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        service_type TEXT NOT NULL,
        date TEXT NOT NULL,
        km INTEGER,
        cost INTEGER,
        notes TEXT,
        bengkel TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_service_records_vehicle_id ON service_records(vehicle_id)',
    );
    await db.execute(
      'CREATE INDEX idx_service_records_date ON service_records(date DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_vehicles_type ON vehicles(vehicle_type)',
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Migrasi akan ditambahkan di phase berikutnya
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
