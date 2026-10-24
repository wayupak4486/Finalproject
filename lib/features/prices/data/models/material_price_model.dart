// ===========================================================================
// 📦 แม่พิมพ์ข้อมูลราคาวัสดุ (MaterialPriceModel)
// ---------------------------------------------------------------------------
// หน้าที่: ใช้เป็นแม่พิมพ์ในการรับ/ส่ง ข้อมูลราคาสิ่งของ 1 ชนิด ระหว่างแอปกับ SQLite
// ===========================================================================

/// แทนข้อมูลหนึ่งแถวในตาราง material_prices หลังอ่านจาก SQLite
class MaterialPriceModel {
  // -------------------------------------------------------------------------
  // 📥 Constructor: บังคับใส่ข้อมูลอะไรบ้างตอนสร้างกล่องนี้
  // -------------------------------------------------------------------------
  const MaterialPriceModel({
    this.id, // ID ปล่อยว่างได้ (เพราะเดี๋ยว Database จะสร้างเลขให้เองตอนเซฟ)
    required this.label,
    required this.displayName,
    required this.category,
    required this.pricePerKg,
    required this.co2Factor,
    required this.source,
    required this.updatedAt,
  });

  // =========================================================================
  // 📦 โซนตัวแปร (Variables)
  // =========================================================================
  final int? id; // รหัสอ้างอิงในฐานข้อมูล
  final String label; // รหัสอ้างอิงของ AI (เช่น 'glass')
  final String displayName; // ชื่อแสดงบนหน้าจอ (เช่น 'ขวดแก้ว')
  final String category; // หมวดหมู่ (เช่น 'แก้ว')
  final double pricePerKg; // ราคารับซื้อ
  final double co2Factor; // อัตราลดคาร์บอน
  final String source; // แหล่งที่มาราคา (เช่น 'Wongpanit' หรือ 'System')
  final DateTime updatedAt; // เวลาที่อัปเดตราคาล่าสุด

  // =========================================================================
  // ⚙️ โซนฟังก์ชันแปลงข้อมูล (Data Serialization)
  // -------------------------------------------------------------------------
  // 🛠️ กฎเหล็ก: ถ้าในอนาคตมีการ "เพิ่มตัวแปรใหม่" ด้านบน ต้องมาเพิ่มใน 2 ฟังก์ชันนี้เสมอ!
  // =========================================================================

  /// 1. ฟังก์ชัน fromMap (แปลงจาก Database -> เป็นแอป)
  /// หน้าที่: รับข้อมูลก้อน Map จาก SQLite มาจับคู่ใส่ตัวแปรทีละตัว
  factory MaterialPriceModel.fromMap(Map<String, Object?> map) {
    return MaterialPriceModel(
      // [ซ้าย] ชื่อตัวแปรในแอป = [ขวา] ชื่อคอลัมน์ในตาราง SQLite
      id: map['id'] as int?,
      label: map['label'] as String,
      displayName: map['display_name'] as String,
      category: map['category'] as String,

      // 💡 ทริคสำคัญ (ไว้ตอบกรรมการ): ต้องใช้ `as num` ก่อน `.toDouble()`
      // เพราะบางครั้ง SQLite จะส่งเลขที่ไม่มีทศนิยมมาเป็น int (เช่น ส่ง 5 มาแทน 5.0)
      // ถ้าเรา as double ตรงๆ แอปจะแครช (Crash) พังทันที!
      pricePerKg: (map['price_per_kg'] as num).toDouble(),
      co2Factor: (map['co2_factor'] as num).toDouble(),
      source: map['source'] as String,

      // SQLite ไม่รู้จักโครงสร้างเวลา (DateTime) ของ Dart เลยเก็บเป็นตัวอักษร
      // ตอนดึงออกมาจึงต้องใช้ DateTime.parse() แปลงข้อความกลับมาเป็นเวลา
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 2. ฟังก์ชัน toMap (แปลงจากแอป -> เป็น Database)
  /// หน้าที่: เตรียมข้อมูลให้พร้อมเซฟลง SQLite โดยแปลงร่างเป็น Map
  Map<String, Object?> toMap() {
    return {
      // 'ชื่อคอลัมน์ในฐานข้อมูล' : ตัวแปรในแอป
      'label': label,
      'display_name': displayName,
      'category': category,
      'price_per_kg': pricePerKg,
      'co2_factor': co2Factor,
      'source': source,

      // ตอนเซฟลง DB ต้องแปลง DateTime ให้เป็นตัวอักษร (String) รูปแบบสากล ISO8601 ก่อน
      // (ตัวอย่าง: '2024-10-21T14:30:00.000')
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
