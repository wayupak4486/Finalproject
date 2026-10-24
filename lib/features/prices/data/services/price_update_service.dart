import '../../../../core/constants/material_catalog.dart';
import '../../../../services/price_source/wongpanit_price_service.dart';
import '../repositories/material_price_repository.dart';

// ===========================================================================
// 📦 คลาสผลลัพธ์การอัปเดต (PriceUpdateResult)
// ---------------------------------------------------------------------------
// 📌 หน้าที่: เป็นกล่องพัสดุสำหรับแพ็ค "ผลสรุป" ส่งกลับไปให้หน้าจอโชว์ให้ผู้ใช้ดู
// ===========================================================================
class PriceUpdateResult {
  const PriceUpdateResult({
    required this.updatedCount, // อัปเดตสำเร็จกี่รายการ
    required this.totalLabels, // รายการขยะในแอปเรามีทั้งหมดกี่รายการ
    required this.updatedAt, // เวลาที่อัปเดต
  });

  final int updatedCount;
  final int totalLabels;
  final DateTime updatedAt;
}

// ===========================================================================
// ⚙️ คลาสผู้จัดการฝ่ายอัปเดตราคา (PriceUpdateService)
// ---------------------------------------------------------------------------
// 📌 หน้าที่: ดึงราคาจากเว็บแบบเรียลไทม์ และเซฟลง SQLite 
// ทำให้ทุกหน้าจอที่อ่านจาก MaterialPriceRepository จะเห็นราคาใหม่ทันที
// ===========================================================================
/// Fetches live prices from the web and persists them into SQLite so every
/// screen that reads [MaterialPriceRepository] reflects the new prices.
class PriceUpdateService {
  // -------------------------------------------------------------------------
  // 📥 Constructor: รับคนงาน 2 คนเข้ามาทำงาน (Repository และ Scraper)
  // -------------------------------------------------------------------------
  PriceUpdateService({
    required this.priceRepository, // บังคับว่าต้องส่งโกดังข้อมูลมาให้
    WongpanitPriceService? scraper, // เครื่องดึงเว็บ (เป็น optional มี ? ต่อท้าย)
  }) : _scraper = scraper ?? WongpanitPriceService(); 
  // 💡 ทริคตอบกรรมการ: "เครื่องหมาย ?? หมายความว่า ถ้าไม่มีการส่ง scraper จำลองเข้ามา 
  // ให้คลาสนี้สร้าง WongpanitPriceService() ตัวจริงขึ้นมาทำงานเองเลยครับ"

  final MaterialPriceRepository priceRepository;
  final WongpanitPriceService _scraper;

  // -------------------------------------------------------------------------
  // 🚀 ฟังก์ชันหลัก: updateFromWeb (กดปุ่มอัปเดตราคา)
  // -------------------------------------------------------------------------
  /// ดึงราคาเว็บ แปลงผลเป็นรายการต่อ label แล้วอัปเดต SQLite ทีละรายการ
  Future<PriceUpdateResult> updateFromWeb() async {
    // สเต็ป 1: await สั่งให้ _scraper ไปขูดข้อมูลจากเว็บวงษ์พาณิชย์ให้เสร็จก่อน
    // ผลลัพธ์ที่ได้จะเป็น Map เช่น {'glass': 1.5, 'aluminum_can': 35.0}
    final scrapedPrices = await _scraper.fetchPrices();
    
    // สเต็ป 2: จดเวลาปัจจุบันเตรียมไว้
    final updatedAt = DateTime.now();

    // สเต็ป 3: นำผลลัพธ์ที่ดึงได้จากเว็บ มาวนลูป (For-loop) เพื่อเซฟลง SQLite ทีละรายการ
    // โดยใช้คำสั่ง upsertPrice เพื่ออัปเดตทับข้อมูลเดิม
    for (final entry in scrapedPrices.entries) {
      await priceRepository.upsertPrice(
        label: entry.key, // คีย์ภาษาอังกฤษ (เช่น 'glass')
        pricePerKg: entry.value, // ราคาที่ดึงมาได้
        source: WongpanitPriceService.sourceName, // แหล่งที่มา ('Wongpanit')
        updatedAt: updatedAt, // เวลาที่เซฟ
      );
    }

    // สเต็ป 4: แพ็คข้อมูลสรุปผล ส่งกลับคืนไปให้หน้าจอแอปพลิเคชัน
    return PriceUpdateResult(
      updatedCount: scrapedPrices.length, // จำนวนรายการที่เว็บดึงมาได้
      
      // 🧮 การคำนวณ totalLabels: 
      // วิ่งไปที่ MaterialCatalog แล้วนับ (length) เฉพาะขยะที่มีสถานะ isSellable (ขายได้) เท่านั้น
      // 💡 ทริคตอบกรรมการ: "ขยะบางประเภทเช่น 'ขยะทั่วไป' ขายไม่ได้ ผมเลยใช้คำสั่ง .where กรองออกก่อนนับยอดรวมครับ"
      totalLabels: MaterialCatalog.byLabel.values
          .where((material) => material.isSellable)
          .length,
          
      updatedAt: updatedAt,
    );
  }
}