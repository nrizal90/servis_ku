import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:servisku/models/vehicle.dart';
import 'package:servisku/models/service_record.dart';

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

  // ─── Vehicle CRUD ──────────────────────────────────────────────────────────

  Future<Vehicle> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    final now = DateTime.now();
    final map = vehicle
        .copyWith(createdAt: now, updatedAt: now)
        .toMap();
    final id = await db.insert('vehicles', map);
    return vehicle.copyWith(id: id, createdAt: now, updatedAt: now);
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final rows = await db.query('vehicles', orderBy: 'created_at DESC');
    return rows.map(Vehicle.fromMap).toList();
  }

  Future<List<Vehicle>> getVehiclesByType(VehicleType type) async {
    final db = await database;
    final rows = await db.query(
      'vehicles',
      where: 'vehicle_type = ?',
      whereArgs: [type.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(Vehicle.fromMap).toList();
  }

  Future<Vehicle?> getVehicleById(int id) async {
    final db = await database;
    final rows = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Vehicle.fromMap(rows.first);
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    await db.update(
      'vehicles',
      vehicle.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<void> deleteVehicle(int id) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // ─── ServiceRecord CRUD ────────────────────────────────────────────────────

  Future<ServiceRecord> insertServiceRecord(ServiceRecord record) async {
    final db = await database;
    final now = DateTime.now();
    final map = record.copyWith(createdAt: now).toMap();
    final id = await db.insert('service_records', map);
    return record.copyWith(id: id, createdAt: now);
  }

  Future<List<ServiceRecord>> getRecordsByVehicle(int vehicleId) async {
    final db = await database;
    final rows = await db.query(
      'service_records',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<List<ServiceRecord>> getAllRecords() async {
    final db = await database;
    final rows = await db.query('service_records', orderBy: 'date DESC');
    return rows.map(ServiceRecord.fromMap).toList();
  }

  Future<ServiceRecord?> getLastRecord(
      int vehicleId, String serviceType) async {
    final db = await database;
    final rows = await db.query(
      'service_records',
      where: 'vehicle_id = ? AND service_type = ?',
      whereArgs: [vehicleId, serviceType],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ServiceRecord.fromMap(rows.first);
  }

  Future<int> getTotalCost(int vehicleId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(cost) as total FROM service_records WHERE vehicle_id = ?',
      [vehicleId],
    );
    return (result.first['total'] as int?) ?? 0;
  }

  Future<void> deleteServiceRecord(int id) async {
    final db = await database;
    await db.delete('service_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
