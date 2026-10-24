import '../../../../core/constants/database_constants.dart';
import '../../../../services/database/app_database.dart';
import '../models/material_price_model.dart';

// ===========================================================================
// 📦 แผนกจัดการข้อมูลราคาวัสดุ (MaterialPriceRepository)
// ---------------------------------------------------------------------------
// 📌 หน้าที่: รวมคำสั่งอ่านและเขียนข้อมูล "ราคาวัสดุ" ผ่านฐานข้อมูล SQLite ของแอป
// ===========================================================================
class MaterialPriceRepository {
  // บังคับว่าตอนเรียกใช้คลาสนี้ ต้องส่งตัวเชื่อมต่อ Database มาให้ด้วย
  MaterialPriceRepository({required this.database});

  // =========================================================================
  // 📦 โซนตัวแปร (Variable)
  // =========================================================================

  // [ตัวแปร] database (รับ AppDatabase instance เดิมจากหน้าจอหรือ service)
  // [หน้าที่] เอาไว้สั่งเปิดฐานข้อมูลเพื่อเตรียม Query ข้อมูล
  final AppDatabase database;

  // =========================================================================
  // ⚙️ โซนดึงข้อมูล (READ)
  // =========================================================================

  // -------------------------------------------------------------------------
  // 📡 ฟังก์ชัน: getAllPrices (ดึงข้อมูลราคาทั้งหมด)
  // [ทำอะไร] ไปดึงแถวราคาทุกแถวในตาราง material_prices มาแปลงเป็น List ของ Model
  // -------------------------------------------------------------------------
  /// อ่านราคาทุกแถวจาก material_prices และเรียงตามชื่อที่แสดง
  Future<List<MaterialPriceModel>> getAllPrices() async {
    // 1. await ขอจับตัวฐานข้อมูล (เปิดโกดัง)
    final db = await database.database;

    // 2. สั่งคำสั่ง Query (เหมือนการเขียน SELECT * FROM material_prices ORDER BY display_name ASC)
    final maps = await db.query(
      DatabaseConstants.materialPricesTable, // ชื่อตาราง
      // 🛠️ วิธีแก้โค้ด: ถ้าอยากเรียงตามราคาจากแพงไปถูก ให้เปลี่ยนบรรทัดล่างเป็น
      // orderBy: 'price_per_kg DESC',
      orderBy: 'display_name ASC', // เรียงตามชื่อภาษาไทย (ASC = จาก ก-ฮ)
    );

    // 3. นำข้อมูลดิบๆ (maps) มาวนลูป .map() ให้ฟังก์ชัน fromMap แปลงร่างเป็น Object
    return maps.map(MaterialPriceModel.fromMap).toList();
  }

  // -------------------------------------------------------------------------
  // 📡 ฟังก์ชัน: getPricesByLabel (ดึงข้อมูลราคาพร้อมแปลงเป็น Map)
  // [ทำอะไร] สร้างพจนานุกรมราคา ที่มี Key เป็นภาษาอังกฤษ และ Value เป็นราคา
  // 💡 เอาไว้ใช้ตอบกรรมการ: "ผมสร้างฟังก์ชันนี้เพื่อหน้า Scan ครับ เวลา AI ทายวัสดุถูกว่ามันคือ 'glass'
  // แอปจะได้วิ่งมาหาใน Map แล้วได้ราคาไปคูณน้ำหนักเลย ไม่ต้องไปวนลูปหาให้แอปช้าครับ"
  // -------------------------------------------------------------------------
  /// คืน map ที่ใช้ label เป็นกุญแจและราคาเป็นค่า สำหรับหน้า Scan
  Future<Map<String, double>> getPricesByLabel() async {
    // 1. ไปขอยืมฟังก์ชัน getAllPrices ด้านบน มาดึงข้อมูลทั้งหมดก่อน
    final prices = await getAllPrices();

    // 2. ใช้เทคนิค Map Comprehension แปลง List เป็น Map
    // ผลลัพธ์ที่ได้จะเป็นแบบนี้ -> {'glass': 1.0, 'aluminum_can': 35.0}
    return {for (final price in prices) price.label: price.pricePerKg};
  }

  // =========================================================================
  // ⚙️ โซนอัปเดตข้อมูล (UPDATE)
  // =========================================================================

  // -------------------------------------------------------------------------
  // 🔄 ฟังก์ชัน: upsertPrice (อัปเดตราคาใหม่ลงตาราง)
  // [ทำอะไร] เอาตัวแปร 4 ตัวที่ได้จากการทำ Web Scraping ไปเซฟทับแถวเดิมตามชื่อ label
  // -------------------------------------------------------------------------
  /// อัปเดตราคา แหล่งที่มา และเวลา โดยค้นหาแถวจาก label
  /// เมธอดนี้ใช้ UPDATE ตาม label ที่มีอยู่ ไม่ได้ INSERT แถวใหม่
  Future<void> upsertPrice({
    required String label, // เช่น 'glass'
    required double pricePerKg, // เช่น 2.5
    required String source, // เช่น 'Wongpanit Web'
    required DateTime updatedAt, // เวลาปัจจุบัน
  }) async {
    final db = await database.database;

    // สั่งอัปเดตฐานข้อมูล (เหมือน SQL: UPDATE material_prices SET price_per_kg = ... WHERE label = 'glass')
    await db.update(
      DatabaseConstants.materialPricesTable, // อัปเดตตารางไหน
      {
        // โยนข้อมูลใหม่ 3 ตัวลงไปทับคอลัมน์เดิม
        'price_per_kg': pricePerKg,
        'source': source,
        'updated_at': updatedAt
            .toIso8601String(), // แปลงเวลาเป็น String ก่อนเซฟลง SQLite
      },
      // 🛠️ ระบบความปลอดภัย: ป้องกัน SQL Injection โดยไม่เอา label ไปต่อข้อความตรงๆ
      where: 'label = ?', // อัปเดตเฉพาะแถวที่ label ตรงกัน
      whereArgs: [
        label,
      ], // whereArgs ส่ง label แยกจาก SQL เพื่อจับคู่แถววัสดุที่ต้องการแก้
    );
  }
}
