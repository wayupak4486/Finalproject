import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _databaseName = 'recycle_ai.db';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE material_prices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        material_name TEXT NOT NULL,
        category TEXT NOT NULL,
        price_per_kg REAL NOT NULL,
        co2_factor REAL NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        image_path TEXT NOT NULL,
        material TEXT NOT NULL,
        category TEXT NOT NULL,
        confidence REAL NOT NULL,
        weight REAL NOT NULL,
        price_per_kg REAL NOT NULL,
        estimated_price REAL NOT NULL,
        co2_saved REAL NOT NULL,
        points_earned INTEGER NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _seedMaterialPrices(db);
  }

  Future<void> _seedMaterialPrices(Database db) async {
    final now = DateTime.now().toIso8601String();

    final materials = [
      {
        'material_name': 'PET Plastic Bottle',
        'category': 'Plastic',
        'price_per_kg': 8.50,
        'co2_factor': 1.50,
        'updated_at': now,
      },
      {
        'material_name': 'HDPE Plastic',
        'category': 'Plastic',
        'price_per_kg': 10.00,
        'co2_factor': 1.70,
        'updated_at': now,
      },
      {
        'material_name': 'Cardboard',
        'category': 'Paper',
        'price_per_kg': 3.00,
        'co2_factor': 0.90,
        'updated_at': now,
      },
      {
        'material_name': 'Aluminum Can',
        'category': 'Metal',
        'price_per_kg': 35.00,
        'co2_factor': 9.00,
        'updated_at': now,
      },
      {
        'material_name': 'Clear Glass',
        'category': 'Glass',
        'price_per_kg': 1.50,
        'co2_factor': 0.30,
        'updated_at': now,
      },
      {
        'material_name': 'Electronic Waste',
        'category': 'Electronic Waste',
        'price_per_kg': 15.00,
        'co2_factor': 2.80,
        'updated_at': now,
      },
    ];

    for (final material in materials) {
      await db.insert('material_prices', material);
    }
  }
}