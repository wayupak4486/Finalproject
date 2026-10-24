import 'package:flutter_test/flutter_test.dart'; // นำเข้าเครื่องมือทำ Unit Test ของ Flutter
import 'package:lastboss/features/history/data/models/history_record_model.dart'; // นำเข้าโมเดลข้อมูลประวัติการสแกน

// ===========================================================================
// ฟังก์ชัน main() สำหรับรันชุดทดสอบ
// ===========================================================================
void main() {
  
  // 💡 สร้างเคสทดสอบการแปลงข้อมูล Model
  test('HistoryRecordModel แปลงข้อมูลสำหรับ SQLite แล้วอ่านกลับได้', () {
    
    // ---------- 1. เตรียมข้อมูลจำลอง (Arrange) ----------
    
    // กำหนดวันเวลาจำลองแบบ UTC (วันที่ 5 สิงหาคม 2026, เวลา 09:30 น.)
    final createdAt = DateTime.utc(2026, 8, 5, 9, 30);
    
    // สร้างออบเจกต์จำลอง (Mock Object) ยัดข้อมูลประวัติการสแกนเข้าไปทุกฟิลด์
    final record = HistoryRecordModel(
      id: 7, // ไอดีรายการ
      imagePath: '/tmp/scan.jpg', // พิกัดรูป
      material: 'ขวดพลาสติก PET', // ชื่อวัสดุ
      category: 'พลาสติก', // หมวดหมู่
      confidence: 92.5, // ความมั่นใจ AI
      weight: 1.25, // น้ำหนัก (กก.)
      pricePerKg: 8.5, // ราคาต่อ กก.
      estimatedPrice: 10.625, // ราคารวม
      co2Saved: 1.875, // คาร์บอนที่ลดได้
      co2FactorPerKg: 1.5, // ค่าคงที่คาร์บอน
      pointsEarned: 18, // คะแนนที่ได้
      note: 'ล้างแล้ว', // หมายเหตุ
      createdAt: createdAt, // วันเวลาที่สร้าง
    );

    // ---------- 2. จำลองกระบวนการทำงานกับ SQLite (Act) ----------
    
    // ขั้น ก (Serialization): แปลงออบเจกต์ให้เป็น Map (Key-Value)
    // และใช้ Cascade Operator (..) เพื่อใส่ค่า 'id' เข้าไปใน Map จำลองเหมือนเวลาดึงมาจากตารางจริง
    final map = record.toMap()..['id'] = record.id;
    
    // ขั้น ข (Deserialization): จำลองการอ่านข้อมูลดิบจาก SQLite (Map) แล้วแปลงกลับมาเป็นออบเจกต์ของแอป
    final restored = HistoryRecordModel.fromMap(map);

    // ---------- 3. ตรวจสอบความถูกต้อง (Assert) ----------
    
    // คาดหวังว่า ID ที่แปลงกลับมา ต้องยังเป็นเลข 7 เท่าเดิม
    expect(restored.id, 7);
    
    // คาดหวังว่า ชื่อวัสดุต้องไม่เพี้ยน
    expect(restored.material, record.material);
    
    // คาดหวังว่า ราคาประเมินต้องคำนวณถูกต้องเท่าเดิม
    expect(restored.estimatedPrice, record.estimatedPrice);
    
    // คาดหวังว่า วันเวลาที่แปลงกลับมาต้องตรงกันเป๊ะ
    expect(restored.createdAt, createdAt);
  });
}