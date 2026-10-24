import 'package:flutter/foundation.dart'; // นำเข้าเครื่องมือพื้นฐานของ Flutter (เพื่อให้รู้จักตัวแปร kDebugMode)
import 'package:sqflite/sqflite.dart'; // นำเข้าปลั๊กอิน SQLite สำหรับจัดการฐานข้อมูล

/// คลาสเครื่องมือพิเศษ เอาไว้สอดส่องข้อมูลใน SQLite (ใช้เฉพาะตอนพัฒนาแอป)
/// โค้ดทุกตัวในนี้จะไม่มีผลอะไรเลยถ้านำแอปไปปล่อยจริง (Production) ปลอดภัย 100%
class DatabaseDebugTool {
  // 💡 สร้าง Private Constructor แบบว่างๆ และใส่ const
  // จุดประสงค์: เพื่อห้ามโปรแกรมเมอร์คนอื่นมาเขียนคำสั่ง `new DatabaseDebugTool()`
  // เพราะคลาสนี้มีแต่ฟังก์ชัน static ไม่จำเป็นต้องสร้างตัวตน (Object) ขึ้นมา
  const DatabaseDebugTool._();

  // ===========================================================================
  // 1. ฟังก์ชันพ่น Log บอกตำแหน่งไฟล์ Database
  // ===========================================================================
  static void logLocation({required String name, required String path}) {
    // 💡 ปราการด่านแรก: kDebugMode คือตัวแปรเช็คว่า "รันผ่านสาย USB/Emulator อยู่ไหม?"[cite: 25]
    // ถ้า kDebugMode เป็น false (คือแอปถูกปล่อยให้ลูกค้าโหลดใน Store แล้ว) ให้ return หยุดทำงานทันที![cite: 25]
    if (!kDebugMode) return;

    // debugPrint จะแสดงข้อความสีขาวๆ ในหน้าต่าง Terminal (Console) ของโปรแกรมเมอร์[cite: 25]
    debugPrint('[DatabaseDebugTool] name: $name');
    debugPrint('[DatabaseDebugTool] path: $path');
  }

  // ===========================================================================
  // 2. ฟังก์ชันกวาดรายชื่อตาราง (ค้นหาตารางทั้งหมดที่เราสร้างไว้)
  // ===========================================================================
  static Future<List<String>> listTables(Database db) async {
    // 💡 sqlite_master คือ "ตารางลับ" ที่ระบบ SQLite สร้างไว้แอบเก็บข้อมูลว่าในนี้มีตารางอะไรบ้าง[cite: 25]
    // ยิง SQL ดิบๆ: "ขอรายชื่อ (name) จากตารางลับ (sqlite_master) โดยเอาเฉพาะของที่เป็นตาราง (type = 'table')"[cite: 25]
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    
    // สิ่งที่ได้มาจะเป็น Map เช่น [{'name': 'history'}, {'name': 'sqlite_sequence'}][cite: 25]
    return tables
        // .map() คือการวนลูป ดึงเอาเฉพาะค่าข้อความที่อยู่ในคีย์ 'name' ออกมา[cite: 25]
        .map((row) => row['name'] as String)
        // .where() คือตัวกรอง: เงื่อนไขคือ ชื่อตารางต้องไม่ (!startsWith) ขึ้นต้นด้วยคำว่า 'sqlite_'[cite: 25]
        // (เพราะตารางที่ขึ้นต้นด้วย sqlite_ คือตารางระบบ เราไม่อยากยุ่ง)[cite: 25]
        .where((name) => !name.startsWith('sqlite_'))
        // .toList() แปลงผลลัพธ์กลับเป็น List ส่งออกไป[cite: 25]
        .toList();
  }

  // ===========================================================================
  // 3. ฟังก์ชันนับจำนวนแถวข้อมูลในตาราง
  // ===========================================================================
  static Future<int> countRows(Database db, String tableName) async {
    // ยิง SQL ดิบๆ: "จงนับทุกสิ่ง (COUNT(*)) และตั้งชื่อผลลัพธ์ว่า count จากตาราง (tableName)"[cite: 25]
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM $tableName',
    );
    // Sqflite.firstIntValue() เป็นเครื่องมือช่วยดึงตัวเลขตัวแรกออกมาจากผลลัพธ์ที่ยุ่งเหยิง[cite: 25]
    // ถ้าพังหรือดึงไม่ได้ (??) ให้ตอบว่ามี 0 บรรทัด[cite: 25]
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ===========================================================================
  // 4. ฟังก์ชันดูดข้อมูลทั้งหมดทุกบรรทัดออกมา
  // ===========================================================================
  static Future<List<Map<String, Object?>>> fetchRows(
    Database db,
    String tableName,
  ) {
    // คำสั่ง .query(ชื่อตาราง) มันมีความหมายเท่ากับ SQL ว่า "SELECT * FROM tableName"[cite: 25]
    return db.query(tableName);
  }

  // ===========================================================================
  // 5. ไม้ตายก้นหีบ: สั่ง Print ทุกตาราง ทุกบรรทัด ลง Terminal (Dump Data)
  // ===========================================================================
  static Future<void> dumpAllTables(Database db) async {
    // ปราการป้องกัน: ถ้านี่เป็นแอปขึ้น Store แล้ว ห้ามทำเด็ดขาด![cite: 25]
    if (!kDebugMode) return;

    try { // ลองทำคำสั่งบล็อกนี้ดู (การทำ Dump เสี่ยงแอปค้าง จึงต้องใช้ Try-Catch)[cite: 25]
      // 1. ไปเรียกฟังก์ชันดึงรายชื่อตารางมา
      final tableNames = await listTables(db);

      // พ่นหัวข้อแจ้งเตือนลง Terminal
      debugPrint('[DatabaseDebugTool] === DEBUG DUMP START ===');
      debugPrint(
        '[DatabaseDebugTool] Tables (${tableNames.length}):$tableNames',
      );

      // 2. วนลูป (For-in) เข้าไปหาตารางทีละชื่อ
      for (final tableName in tableNames) {
        // นับจำนวนบรรทัดของตารางนั้น แล้วพิมพ์บอก
        final count = await countRows(db, tableName);
        debugPrint('[DatabaseDebugTool] Table "$tableName": $count row(s)');

        // ดึงข้อมูลจริงออกมา
        final rows = await fetchRows(db, tableName);
        // 3. วนลูป (For-i) เข้าไปพิมพ์ข้อมูลทีละบรรทัดลงใน Terminal
        for (var i = 0; i < rows.length; i++) {
          debugPrint('[DatabaseDebugTool]   [$tableName][$i]${rows[i]}');
        }
      }

      // พ่นแจ้งว่าจบการ Dump แล้ว
      debugPrint('[DatabaseDebugTool] === DEBUG DUMP END ===');
    } catch (e, stackTrace) {
      // ถ้ากระบวนการใดพัง ให้พ่นข้อความ Error พร้อม StackTrace (ร่องรอยการพัง) ให้โปรแกรมเมอร์ตามไปแก้ถูกที่[cite: 25]
      debugPrint('[DatabaseDebugTool] dumpAllTables() failed: $e');
      debugPrint('[DatabaseDebugTool] $stackTrace');
    }
  }
}