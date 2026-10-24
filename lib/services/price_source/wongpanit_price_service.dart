import 'package:http/http.dart' as http; // นำเข้าเครื่องมือสำหรับคุยกับอินเทอร์เน็ต (ย่อชื่อให้เรียกสั้นๆ ว่า http)

import 'price_page_parser.dart'; // นำเข้าลูกน้องนักสับ HTML ของเรา

// ===========================================================================
// คลาสสำหรับสร้าง "Error แบบเฉพาะเจาะจง" 
// (สืบทอดมาจาก Exception ของระบบ Dart)
// ===========================================================================
class PriceFetchException implements Exception {
  // รับข้อความแจ้งเตือนมาเก็บไว้
  PriceFetchException(this.message);

  final String message; // ตัวแปรเก็บข้อความ (เช่น 'เว็บล่ม', 'เน็ตหลุด')

  // เขียนทับ (Override) ฟังก์ชัน toString เพื่อเวลาปรินต์ Error จะได้โชว์ข้อความของเราเลย
  @override
  String toString() => message;
}

// ===========================================================================
// คลาสหลัก: พนักงานวิ่งเอกสาร (Scraper Service)
// ===========================================================================
/// สกัดตารางราคารับซื้อจากเว็บวงษ์พาณิชย์
/// และแปลงแต่ละแถวให้ตรงกับ Label ของขยะในแอปเรา
class WongpanitPriceService {
  
  // 💡 Constructor แบบ Dependency Injection (DI)
  // อนุญาตให้ส่งตัวจำลอง (Mock) ของ Client หรือ Parser เข้ามาได้
  // ถ้าไม่ส่งมา (??) ก็ให้สร้าง PricePageParser() ตัวจริงขึ้นมาใช้
  WongpanitPriceService({http.Client? client, PricePageParser? parser})
    : _client = client,
      _parser = parser ?? const PricePageParser();

  // 💡 ตัวแปร static const: กำหนดพิกัดเป้าหมาย (URL) ตายตัวไปเลย
  static const String sourceUrl =
      'https://www.xn--12c7bzakgbj6bza1cbe6b3jwh.com/price'; // โดเมนวงษ์พาณิชย์ที่เป็นภาษาไทย จะถูกแปลงเป็นภาษาต่างดาว (Punycode) แบบนี้

  // ชื่อแหล่งที่มาของราคา เอาไว้เก็บลง Database
  static const String sourceName = 'wongpanit';

  // ตัวแปรเก็บเครื่องมือที่ถูกส่งมาตอนสร้างคลาส
  final http.Client? _client;
  final PricePageParser _parser;

  // ===========================================================================
  // 🚪 ฟังก์ชันหลัก: ดาวน์โหลดเว็บและดึงราคา (เป็นแบบ Async เพราะต้องรอเน็ต)
  // ===========================================================================
  Future<Map<String, double>> fetchPrices() async {
    final http.Response response; // ตัวแปรสำหรับรับพัสดุจากอินเทอร์เน็ต

    // 1. ลองทำบล็อก try-catch เพื่อดักจับปัญหาเรื่องอินเทอร์เน็ตหลุด/ช้า
    try {
      // 💡 เงื่อนไข ?? : ถ้า _client ที่ส่งมาไม่ว่างเปล่า ให้ใช้ _client.get() 
      // แต่ถ้าว่างเปล่า ให้ใช้การโหลด http.get() พื้นฐานของแพ็กเกจแทน
      response =
          await (_client?.get(Uri.parse(sourceUrl)) ??
                  http.get(Uri.parse(sourceUrl)))
              // 💡 ป้องกันแอปค้าง: ถ้าเว็บโหลดนานเกิน 20 วินาที ให้ตัดจบ (throw TimeoutException)
              .timeout(const Duration(seconds: 20));
              
    } catch (error) {
      // ถ้าจับ Error ได้ (เช่น ไม่มีเน็ต, โหลดเกิน 20 วิ) 
      // ให้โยน PriceFetchException กลับไปให้คนเรียกใช้งาน พร้อมแนบข้อความบอกสาเหตุ
      throw PriceFetchException('ไม่สามารถเชื่อมต่อเว็บไซต์ราคาได้: $error');
    }

    // 2. เช็คสถานะการตอบกลับของเซิร์ฟเวอร์
    // HTTP Status 200 = OK (เว็บโหลดสำเร็จและมีข้อมูล)
    // ถ้าไม่ใช่ 200 (เช่น 404 หน้าหาย, 500 เซิร์ฟพัง) จะเข้าเงื่อนไขนี้
    if (response.statusCode != 200) {
      throw PriceFetchException(
        'เว็บไซต์ราคาตอบกลับสถานะ ${response.statusCode}',
      );
    }

    // 3. เมื่อได้โค้ด HTML มาอย่างปลอดภัยแล้ว ส่งตัวอักษรทั้งหมด (response.body)
    // ไปให้ฟังก์ชัน parsePrices ของลูกน้องช่วยสับตารางให้
    final prices = _parser.parsePrices(response.body);

    // 4. ตรวจสอบความถูกต้องรอบสุดท้าย (Data Validation)
    // ถ้าสับตารางเสร็จแล้วได้ตารางว่างเปล่า แปลว่าเว็บวงษ์พาณิชย์อาจจะเปลี่ยนหน้าตาเว็บใหม่
    // ทำให้ลูกน้องเรา (Parser) หาคำไม่เจอ
    if (prices.isEmpty) {
      throw PriceFetchException('ไม่พบวัสดุที่รู้จักในหน้าราคา');
    }

    // 5. ส่งตารางราคาสุทธิ กลับไปให้ระบบเอาไปใช้งาน
    return prices;
  }
}