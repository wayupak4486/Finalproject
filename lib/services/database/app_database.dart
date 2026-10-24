import 'package:path/path.dart'; // นำเข้าตัวช่วยจัดการชื่อไฟล์และเส้นทาง (Path) ในเครื่องมือถือ
import 'package:sqflite/sqflite.dart'; // นำเข้าปลั๊กอินฐานข้อมูล SQLite สุดฮิตของ Flutter

import '../../core/constants/database_constants.dart'; // นำเข้าไฟล์เก็บชื่อตารางและเวอร์ชัน (เพื่อไม่ให้พิมพ์ชื่อตารางผิด)
import '../../core/constants/material_catalog.dart'; // นำเข้าแคตตาล็อกขยะ เพื่อเอามาเป็นข้อมูลตั้งต้น (Seed)
import 'database_debug_tool.dart'; // นำเข้าเครื่องมือสำหรับพ่น log ดูตารางตอนทดสอบ

/// คลาส AppDatabase: ศูนย์กลางเปิดฐานข้อมูลและจัดการสร้าง/อัปเกรด
class AppDatabase {
  // 💡 สร้าง Private Constructor (_ นำหน้า) เพื่อ "ห้าม" ไม่ให้ไฟล์อื่นสร้างออบเจกต์คลาสนี้แบบปกติ (new AppDatabase())
  AppDatabase._();

  // 💡 สร้าง Singleton Instance (สร้างตัวเองเก็บไว้ในตัวแปรแบบ static)
  // ไฟล์อื่นจะเรียกผ่าน AppDatabase.instance เท่านั้น (มีท่อเดียวในแอป)
  static final AppDatabase instance = AppDatabase._();

  // ตัวแปรเก็บท่อเชื่อมต่อฐานข้อมูล (เป็น null ได้ถ้ายังไม่เคยเปิด)
  Database? _database;

  // ===========================================================================
  // 🚪 ประตูหลัก: ฟังก์ชันดึงฐานข้อมูล (Getter)
  // ===========================================================================
  Future<Database> get database async {
    // 1. เช็คก่อนว่ามีท่อเชื่อมเปิดค้างไว้ไหม ถ้ามี (ไม่เท่ากับ null) ให้ส่งกลับไปใช้เลย ประหยัดเวลา
    if (_database != null) {
      return _database!; // เครื่องหมาย ! แปลว่า "มั่นใจว่าไม่ null แน่นอน"
    }

    // 2. ถ้ายังไม่เคยเปิด ให้เรียกฟังก์ชัน _initDatabase() สร้างท่อเชื่อมใหม่
    _database = await _initDatabase();

    // พ่น Log ตารางทั้งหมดลง Console (เห็นเฉพาะโหมด Debug)
    await DatabaseDebugTool.dumpAllTables(_database!);

    return _database!; // ส่งท่อเชื่อมให้คนอื่นไปใช้งาน
  }

  // ===========================================================================
  // ⚙️ ฟังก์ชันตั้งต้น: หาระบุตำแหน่งไฟล์และเปิด Database
  // ===========================================================================
  Future<Database> _initDatabase() async {
    // สั่งระบบมือถือ (iOS/Android) ว่า "ขอที่อยู่แฟ้มสำหรับเก็บ Database หน่อย"
    final databasePath = await getDatabasesPath();
    // นำที่อยู่แฟ้ม มาต่อกับชื่อไฟล์ (เช่น 'app.db') ด้วยฟังก์ชัน join
    final path = join(databasePath, DatabaseConstants.databaseName);

    // พ่น Log บอกที่อยู่ไฟล์
    DatabaseDebugTool.logLocation(
      name: DatabaseConstants.databaseName,
      path: path,
    );

    // 💡 คำสั่งเปิดฐานข้อมูล
    final db = await openDatabase(
      path, // ที่อยู่ไฟล์
      version: DatabaseConstants
          .databaseVersion, // บอกเวอร์ชันปัจจุบัน (ถ้าเลขนี้เปลี่ยน มันจะไปเรียก onUpgrade)
      onCreate: _onCreate, // ถ้าไฟล์ไม่เคยมีอยู่เลย ให้เรียกฟังก์ชันนี้
      onUpgrade:
          _onUpgrade, // ถ้าไฟล์มีอยู่แล้วแต่เลข version เก่ากว่า ให้เรียกฟังก์ชันนี้
    );

    // เช็คความชัวร์ว่าตารางราคาต้องมีข้อมูลนะ! (ป้องกันตารางว่างเปล่า)
    await _ensureMaterialPricesSeeded(db);

    return db;
  }

  // ฟังก์ชันพิเศษสำหรับโหมดพัฒนา เอาไว้พ่นข้อมูลตารางออกมาดู
  Future<void> debugDatabase() async {
    final db = await database;
    await DatabaseDebugTool.dumpAllTables(db);
  }

  // ===========================================================================
  // 🛡️ ฟังก์ชันป้องกันบั๊ก: เช็คว่าตารางราคาว่างไหม? ถ้าว่างให้เติมข้อมูล (Seed)
  // ===========================================================================
  Future<void> _ensureMaterialPricesSeeded(Database db) async {
    // 1. ลองเช็คระบบ Master ของ SQLite ก่อนว่า "มีตารางชื่อ material_prices โผล่มาหรือยัง?"
    final tables = await db.query(
      'sqlite_master', // ตารางระบบที่เก็บรายชื่อตารางทั้งหมด
      where:
          'type = ? AND name = ?', // เงื่อนไข: ต้องเป็นตาราง และชื่อตรงกับที่เราหา
      whereArgs: ['table', DatabaseConstants.materialPricesTable],
    );

    // 2. ถ้ายังไม่มีตารางเลย (isEmpty) ให้สั่งสร้างตาราง แล้วยัดข้อมูลเลย
    if (tables.isEmpty) {
      await _createMaterialPricesTable(db);
      await _seedMaterialPrices(db);
      return; // จบงาน
    }

    // 3. ถ้ามีตารางแล้ว ให้ลองนับจำนวนข้อมูล (COUNT) ดูว่ามีกี่บรรทัด
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DatabaseConstants.materialPricesTable}',
    );
    // แปลงผลลัพธ์เป็นตัวเลข (ถ้าพังให้เป็น 0)
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    // 4. ถ้าตารางมีแต่เปลือก ไม่มีข้อมูล (count == 0) ให้สั่งยัดข้อมูลเลย
    if (count == 0) {
      await _seedMaterialPrices(db);
    }
  }

  // ===========================================================================
  // 🏗️ ฟังก์ชันสร้างบ้านใหม่: ทำงานเมื่อโหลดแอป "ครั้งแรกในชีวิต" (onCreate)
  // ===========================================================================
  Future<void> _onCreate(Database db, int version) async {
    // 1. สร้างตารางราคาวัสดุ
    await _createMaterialPricesTable(db);

    // 2. สร้างตารางประวัติการสแกน (ใช้คำสั่ง SQL)
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.historyTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- คอลัมน์ id เป็นเลขรันอัตโนมัติ (1, 2, 3...)
        image_path TEXT NOT NULL, -- พิกัดรูปภาพ (ข้อความ ห้ามว่าง)
        material TEXT NOT NULL, -- ชื่อวัสดุ (ห้ามว่าง)
        category TEXT NOT NULL, -- หมวดหมู่
        confidence REAL NOT NULL, -- ความมั่นใจ AI (REAL คือเลขทศนิยม)
        weight REAL NOT NULL, -- น้ำหนัก
        price_per_kg REAL NOT NULL, -- ราคา
        estimated_price REAL NOT NULL, -- ราคารวม
        co2_saved REAL NOT NULL, -- คาร์บอนรวม
        co2_factor_per_kg REAL NOT NULL DEFAULT 0, -- ค่าคงที่คาร์บอน (ค่าเริ่มต้นเป็น 0)
        points_earned INTEGER NOT NULL, -- คะแนน (เลขจำนวนเต็ม)
        note TEXT, -- หมายเหตุ (ว่างได้)
        created_at TEXT NOT NULL -- วันที่สร้าง (เก็บเป็นข้อความ)
      )
    ''');

    // 3. ยัดข้อมูลราคาเริ่มต้น
    await _seedMaterialPrices(db);
  }

  // ===========================================================================
  // 🔧 ฟังก์ชันต่อเติมบ้าน: ทำงานเมื่ออัปเดตแอป (onUpgrade)
  // ===========================================================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // ถ้าของเดิมเก่ากว่าเวอร์ชัน 2 (แสดงว่าใช้ตารางราคาแบบเก่า) ให้ย้ายข้อมูลไปแบบใหม่
    if (oldVersion < 2) {
      await _migrateLegacyMaterialPrices(db);
    }

    // 💡 ถ้าของเดิมเก่ากว่าเวอร์ชัน 4 ให้ "เพิ่มคอลัมน์ใหม่" ชื่อ co2_factor_per_kg เข้าไปในตาราง history
    // สาเหตุ: ฟีเจอร์เวอร์ชันใหม่ต้องการค่านี้ แต่ตารางเก่าไม่มี เลยต้องใช้คำสั่ง ALTER TABLE สั่งเพิ่มเข้าไป
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${DatabaseConstants.historyTable} '
        'ADD COLUMN co2_factor_per_kg REAL NOT NULL DEFAULT 0',
      );
    }
  }

  // ===========================================================================
  // 📦 ฟังก์ชันย้ายของ: ย้ายตารางราคา v1 ไป v2 (เปลี่ยนจากการอ้างอิงชื่อ มาอ้างอิง label)
  // ===========================================================================
  Future<void> _migrateLegacyMaterialPrices(Database db) async {
    const legacyTable = 'material_prices_v1';
    // 1. เปลี่ยนชื่อตารางเก่าทิ้งไปก่อน เพื่อหลีกทางให้ตารางใหม่
    await db.execute(
      'ALTER TABLE ${DatabaseConstants.materialPricesTable} RENAME TO $legacyTable',
    );
    // 2. สร้างตารางใหม่ที่โครงสร้างถูกต้อง
    await _createMaterialPricesTable(db);
    // 3. ยัดข้อมูลค่าเริ่มต้นของตารางใหม่ลงไปรอ
    await _seedMaterialPrices(db);

    // 4. สร้างแผนที่แปลงชื่อวัสดุแบบเก่า ให้กลายเป็น Label แบบใหม่
    const labelByLegacyName = {
      'PET Plastic Bottle': 'pet_plastic_bottle',
      'HDPE Plastic': 'hdpe_plastic',
      'Cardboard': 'paper_cardboard',
      'Aluminum Can': 'aluminum_can',
      'Clear Glass': 'glass',
    };

    // ดึงข้อมูลจากตารางเก่ามาทั้งหมด
    final legacyPrices = await db.query(legacyTable);

    // วนลูปเอาข้อมูลเก่า ไปปรับปรุง (Update) ทับข้อมูลใหม่ เพื่อให้ "ราคาที่ผู้ใช้เคยแก้ไว้" ไม่หายไป
    for (final price in legacyPrices) {
      final label = labelByLegacyName[price['material_name']];
      if (label == null) continue; // ถ้าหา label ไม่เจอ ให้ข้ามไป

      // สั่งอัปเดตราคาเก่าทับลงไป
      await db.update(
        DatabaseConstants.materialPricesTable,
        {
          'price_per_kg': price['price_per_kg'],
          'co2_factor': price['co2_factor'],
          'source': 'legacy',
          'updated_at': price['updated_at'],
        },
        where: 'label = ?', // เงื่อนไข: แก้ไขเฉพาะบรรทัดที่ label ตรงกัน
        whereArgs: [label],
      );
    }

    // 5. โยนตารางเก่าทิ้ง
    await db.execute('DROP TABLE $legacyTable');
  }

  // ===========================================================================
  // 📋 คำสั่งสร้างตารางราคากลาง
  // ===========================================================================
  Future<void> _createMaterialPricesTable(Database db) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.materialPricesTable} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        label TEXT NOT NULL UNIQUE, -- UNIQUE แปลว่าคอลัมน์ label ห้ามมีข้อมูลซ้ำกันเด็ดขาด
        display_name TEXT NOT NULL,
        category TEXT NOT NULL,
        price_per_kg REAL NOT NULL,
        co2_factor REAL NOT NULL,
        source TEXT NOT NULL DEFAULT 'default',
        updated_at TEXT NOT NULL
      )
    ''');
  }

  // ===========================================================================
  // 🌱 ฟังก์ชันปลูกเมล็ดพันธุ์: ยัดข้อมูลราคาเริ่มต้น (Seed)
  // ===========================================================================
  Future<void> _seedMaterialPrices(Database db) async {
    final now = DateTime.now().toIso8601String(); // ดึงเวลาปัจจุบัน

    // วนลูปข้อมูลขยะทั้งหมดที่มีใน Catalog
    for (final entry in MaterialCatalog.byLabel.entries) {
      // สั่ง INSERT ลงตาราง
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
        // 💡 จุดสำคัญมาก: ConflictAlgorithm.ignore
        // แปลว่า "ถ้าเกิดไปยัดข้อมูล label ที่มีอยู่แล้ว (ซ้ำ) ก็ให้เพิกเฉยทิ้งไปเลย ไม่ต้อง error"
        // ป้องกันแอปพังเวลาเราเรียกฟังก์ชันนี้ซ้ำหลายรอบ
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}
