import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/database_constants.dart';
import '../../core/constants/material_catalog.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

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
    final path = join(databasePath, DatabaseConstants.databaseName);

    final db = await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    await _ensureMaterialPricesSeeded(db);

    return db;
  }

  /// Guards against a `material_prices` table left empty by an interrupted
  /// migration or a stale dev build whose stored schema version already
  /// matches [DatabaseConstants.databaseVersion] (so [_onUpgrade] would not
  /// run again).
  Future<void> _ensureMaterialPricesSeeded(Database db) async {
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', DatabaseConstants.materialPricesTable],
    );

    if (tables.isEmpty) {
      await _createMaterialPricesTable(db);
      await _seedMaterialPrices(db);
      return;
    }

    final countResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DatabaseConstants.materialPricesTable}',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    if (count == 0) {
      await _seedMaterialPrices(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createMaterialPricesTable(db);

    await db.execute('''
      CREATE TABLE ${DatabaseConstants.historyTable} (
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateLegacyMaterialPrices(db);
    }
  }

  /// Version 1 used material names instead of stable model labels. Preserve
  /// known prices while moving to the label-based schema rather than dropping
  /// the table (which would discard the most recently stored values).
  Future<void> _migrateLegacyMaterialPrices(Database db) async {
    const legacyTable = 'material_prices_v1';
    await db.execute(
      'ALTER TABLE ${DatabaseConstants.materialPricesTable} RENAME TO $legacyTable',
    );
    await _createMaterialPricesTable(db);
    await _seedMaterialPrices(db);

    const labelByLegacyName = {
      'PET Plastic Bottle': 'pet_plastic_bottle',
      'HDPE Plastic': 'hdpe_plastic',
      'Cardboard': 'paper_cardboard',
      'Aluminum Can': 'aluminum_can',
      'Clear Glass': 'glass',
    };
    final legacyPrices = await db.query(legacyTable);

    for (final price in legacyPrices) {
      final label = labelByLegacyName[price['material_name']];
      if (label == null) continue;

      await db.update(
        DatabaseConstants.materialPricesTable,
        {
          'price_per_kg': price['price_per_kg'],
          'co2_factor': price['co2_factor'],
          'source': 'legacy',
          'updated_at': price['updated_at'],
        },
        where: 'label = ?',
        whereArgs: [label],
      );
    }

    await db.execute('DROP TABLE $legacyTable');
  }

  Future<void> _createMaterialPricesTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.materialPricesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        category TEXT NOT NULL,
        price_per_kg REAL NOT NULL,
        co2_factor REAL NOT NULL,
        source TEXT NOT NULL DEFAULT 'default',
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedMaterialPrices(Database db) async {
    final now = DateTime.now().toIso8601String();

    for (final entry in MaterialCatalog.byLabel.entries) {
      await db.insert(
        DatabaseConstants.materialPricesTable,
        {
          'label': entry.key,
          'display_name': entry.value.displayName,
          'category': entry.value.category,
          'price_per_kg': entry.value.pricePerKg,
          'co2_factor': entry.value.co2FactorPerKg,
          'source': 'default',
          'updated_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
