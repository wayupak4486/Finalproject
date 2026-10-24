import 'package:html/parser.dart' as html_parser; // นำเข้าไลบรารีสำหรับแปลงข้อความ HTML ให้กลายเป็น DOM Tree เหมือนในเว็บ

// ===========================================================================
// กล่องแพ็คข้อมูลขนาดเล็ก (Data Transfer Object)
// เอาไว้เก็บข้อมูลดิบๆ ที่ดึงมาจากแต่ละบรรทัดของตารางเว็บวงษ์พาณิชย์
// ===========================================================================
class _ScrapedItem {
  const _ScrapedItem({required this.name, required this.pricePerKg});
  final String name; // ชื่อวัสดุบนหน้าเว็บ
  final double pricePerKg; // ราคาที่ดึงมาได้
}

/// คลาสสำหรับวิเคราะห์ (Parse) หน้าเว็บวงษ์พาณิชย์ โดยไม่มีการต่อเน็ตในไฟล์นี้!
/// การแยก Parse ออกมาเดี่ยวๆ ทำให้เราสามารถเขียน Automated Test ทดสอบกับไฟล์ HTML จำลองได้ง่าย
class PricePageParser {
  const PricePageParser();

  // ===========================================================================
  // 📚 พจนานุกรมคำศัพท์ (Keywords Mapping)
  // แมปปิ้งระหว่าง "รหัสวัสดุในแอป (Label)" จับคู่กับ "คำที่ใช้เรียกบนหน้าเว็บ"
  // ถ้าเว็บเปลี่ยนคำเขียน เราแค่มาแก้เพิ่มคำใน List นี้ได้เลย
  // ===========================================================================
  static const Map<String, List<String>> _keywordsByLabel = {
    'pet_plastic_bottle': ['พลาสติกเพทใส ไม่แกะ'], // ขวด PET
    'hdpe_plastic': ['แกลลอนนม'], // พลาสติก HDPE
    'paper_cardboard': ['กระดาษลัง'], // ลังกระดาษ
    'aluminum_can': ['อลูมิเนียมกระป๋อง'], // กระป๋อง
    'glass': ['แก้วรวม'], // แก้ว
    'steel_scrap': ['เหล็กรวม'], // เหล็ก
  };

  // ===========================================================================
  // 🚪 ฟังก์ชันหลัก: รับโค้ด HTML ดิบ -> คืนค่าตารางราคาสุทธิ
  // ===========================================================================
  Map<String, double> parsePrices(String body) {
    // 1. ส่งโค้ด HTML ไปให้ลูกน้องชำแหละตาราง ได้ลิสต์ของทุกแถวมา
    final items = _parseItems(body);
    
    // 2. สร้างตารางเปล่าๆ รอรับข้อมูลที่แมตช์แล้ว
    final prices = <String, double>{};

    // 3. วนลูปรายชื่อขยะที่เราต้องการหา (ตามพจนานุกรม _keywordsByLabel)
    for (final entry in _keywordsByLabel.entries) {
      // เอาคำไปวิ่งหาในลิสต์ items ว่าเจอตรงกันไหม
      final price = _findPrice(items, entry.value);
      
      // ถ้าเจอราคา (ไม่เป็น null) ก็ให้บันทึกใส่ตาราง prices
      if (price != null) {
        prices[entry.key] = price;
      }
    }

    return prices; // ส่งตารางราคากลับไปให้ระบบ Database
  }

  // ===========================================================================
  // 🕵️ ฟังก์ชันเจาะตาราง HTML (DOM Parser)
  // ===========================================================================
  List<_ScrapedItem> _parseItems(String body) {
    // แปลงข้อความ HTML ยาวๆ ให้กลายเป็น Document Object (ต้นไม้โครงสร้างเว็บ)
    final document = html_parser.parse(body);
    
    // ค้นหาแท็ก 'table tr' (แถวทั้งหมดที่อยู่ในตาราง)
    final rows = document.querySelectorAll('table tr');
    final items = <_ScrapedItem>[]; // กล่องรอรับข้อมูล

    // วนลูปทีละแถว (tr)
    for (final row in rows) {
      // ค้นหาช่อง (td) ในแถวนั้นๆ
      final cells = row.querySelectorAll('td');
      // ถ้าแถวนั้นมีช่องน้อยกว่า 2 ช่อง แปลว่าไม่ใช่ข้อมูลขยะ ให้ข้ามไป (continue)
      if (cells.length < 2) continue;

      // 💡 ภารกิจหาช่อง "ชื่อวัสดุ" (เพราะหน้าเว็บอาจจะเอาช่อง "ลำดับที่" ขึ้นก่อน)
      // หาช่องแรกที่ "ไม่ใช่ตัวเลขเพียวๆ"
      final nameIndex = cells.indexWhere((cell) => !_isPureNumber(cell.text));
      if (nameIndex == -1) continue; // ถ้าหาไม่เจอเลย ข้ามไป

      // เอาข้อความช่องนั้นมาทำความสะอาด (ตัดเลขลำดับ ลบช่องว่าง)
      final name = _cleanName(cells[nameIndex].text);
      if (name.isEmpty) continue; // ถ้าทำความสะอาดแล้วว่างเปล่า ข้ามไป

      double? price;
      // 💡 ภารกิจหาช่อง "ราคา"
      // ข้ามช่องชื่อวัสดุไป (.skip) แล้ววนลูปช่องที่เหลือเพื่อหาว่าช่องไหนมีตัวเลขราคาอยู่
      for (final cell in cells.skip(nameIndex + 1)) {
        price = _tryParsePrice(cell.text); // ลองแปลงดูว่าดึงเลขได้ไหม
        if (price != null) break; // ถ้าดึงเลขได้สำเร็จ แปลว่าช่องนี้คือช่องราคา ให้หยุดหา (break)
      }

      // ถ้าหาทั้งชื่อและราคาเจอครบ ก็แพ็คใส่กล่อง _ScrapedItem เก็บไว้
      if (price != null) {
        items.add(_ScrapedItem(name: name, pricePerKg: price));
      }
    }

    return items; // คืนค่าตารางข้อมูลดิบ
  }

  // ===========================================================================
  // 🧹 โซนเครื่องมือทำความสะอาดข้อความ (RegEx Utility)
  // ===========================================================================

  // เช็คว่าเป็นตัวเลขเพียวๆ ใช่ไหม?
  // RegExp ^\d+$ แปลว่า "ตั้งแต่ต้น(^) ถึงจบ($) ต้องเป็นตัวเลข(\d) ที่มี 1 ตัวขึ้นไป(+)"
  bool _isPureNumber(String raw) => RegExp(r'^\d+$').hasMatch(raw.trim());

  // ทำความสะอาดชื่อวัสดุ
  String _cleanName(String raw) {
    // 1. ลบช่องว่างหัวท้าย (.trim) และยุบช่องว่างหลายๆ เคาะ ให้เหลือเคาะเดียว ( \s+ เปลี่ยนเป็น ' ' )
    final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    // 2. ลบลำดับข้อด้านหน้าทิ้ง!
    // RegExp ^\d+[.)]\s* แปลว่า "ถ้าเริ่มด้วยตัวเลข ตามด้วยจุดหรือวงเล็บปิด ตามด้วยช่องว่าง ให้ลบทิ้ง!"
    // ตัวอย่าง: "1. ขวดแก้ว" หรือ "2) กระดาษ" จะกลายเป็น "ขวดแก้ว" กับ "กระดาษ"
    return collapsed.replaceFirst(RegExp(r'^\d+[.)]\s*'), '');
  }

  // ดึงตัวเลขราคาออกมาจากข้อความที่มีตัวอักษรปน
  double? _tryParsePrice(String raw) {
    // ตัดลูกน้ำทิ้งก่อน (เช่น "1,200 บาท" -> "1200 บาท")
    final normalized = raw.trim().replaceAll(',', '');
    
    // RegExp ดึงเฉพาะกลุ่มตัวเลขและทศนิยม
    // -? (มีลบหรือไม่มีก็ได้) \d+ (ตัวเลข) (\.\d+)? (มีจุดทศนิยมหรือไม่มีก็ได้)
    final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(normalized);
    
    // ถ้าดึงเลขออกมาได้ ให้ลองแปลงเป็น double
    return match == null ? null : double.tryParse(match.group(0)!);
  }

  // ===========================================================================
  // 🔍 ฟังก์ชันค้นหาราคา
  // ===========================================================================
  // เอา keyword (เช่น 'พลาสติกเพทใส ไม่แกะ') ไปวิ่งหาในลิสต์ items ที่ดึงมา
  double? _findPrice(List<_ScrapedItem> items, List<String> keywords) {
    for (final keyword in keywords) {
      for (final item in items) {
        // ถ้าชื่อที่ดูดมา มีคำ keyword นี้ซ่อนอยู่ ให้ตอบราคากลับไปเลย
        if (item.name.contains(keyword)) return item.pricePerKg;
      }
    }
    return null; // ถ้าหาไม่เจอ ให้คืนค่า null
  }
}