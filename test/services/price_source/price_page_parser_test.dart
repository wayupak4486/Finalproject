import 'dart:io'; // นำเข้าเครื่องมือจัดการไฟล์ (เอาไว้เปิดอ่านไฟล์ Fixture)

import 'package:flutter_test/flutter_test.dart'; // นำเข้าชุดเครื่องมือทำ Unit Test ของ Flutter
import 'package:http/http.dart' as http; // นำเข้าแพ็กเกจ http
import 'package:lastboss/services/price_source/price_page_parser.dart'; // นำเข้าตัวสับ HTML
import 'package:lastboss/services/price_source/wongpanit_price_service.dart'; // นำเข้าเซอร์วิสจัดการดึงราคา

// ===========================================================================
// 🛠️ คลาสหน้าม้า (Fake Client สำหรับจำลองการตอบกลับของอินเทอร์เน็ต)
// สืบทอดมาจาก http.BaseClient เพื่อให้ปลอมตัวเป็นเน็ตจริงได้เนียนๆ
// ===========================================================================
class _FakeClient extends http.BaseClient {
  _FakeClient(this.response); // รับ Response ปลอมเข้ามาตอนสร้างคลาส

  final http.Response response; // เก็บ Response ปลอมไว้ข้างใน

  // เขียนทับฟังก์ชัน send เพื่อบังคับให้มันส่ง Response ปลอมของเราออกไปทุกครั้งที่มีการเรียกใช้เน็ต
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(response.bodyBytes), // แปลงเนื้อหาเป็น Stream
      response.statusCode, // คืนค่าสถานะจำลอง (เช่น 200, 503)
      headers: response.headers,
    );
  }
}

// ===========================================================================
// ฟังก์ชัน main() สำหรับรันชุดทดสอบ
// ===========================================================================
void main() {
  
  // ---------- 🧪 เคสทดสอบที่ 1: ตรวจสอบการสกัดราคาจากไฟล์ HTML จำลอง (Fixture Test) ----------
  test('parser อ่านตารางราคา fixture และเลือกเฉพาะวัสดุที่รองรับ', () async {
    
    // 1. โหลดไฟล์ HTML จำลอง (Fixture) ที่เซฟเตรียมไว้ในโปรเจกต์ขึ้นมาอ่านเป็นข้อความ
    final fixture = await File(
      'test/fixtures/wongpanit_price.html',
    ).readAsString();

    // 2. สั่งให้ PricePageParser แปลงข้อความ HTML นั้น และใช้ expect เช็คผลลัพธ์
    // คาดหวังว่า Map ที่ได้ จะต้องสกัดราคาขยะทั้ง 6 ชนิดออกมาได้ตรงเป๊ะตามเรทในไฟล์ Fixture
    expect(const PricePageParser().parsePrices(fixture), {
      'pet_plastic_bottle': 8.5,
      'hdpe_plastic': 7.25,
      'paper_cardboard': 3.0,
      'aluminum_can': 35.0,
      'glass': 1.0,
      'steel_scrap': 6.0,
    });
  });

  // ---------- 🧪 เคสทดสอบที่ 2: ตรวจสอบการจัดการ Error เมื่อเว็บล่ม (Error Handling Test) ----------
  test('service แจ้งข้อผิดพลาดเมื่อเว็บตอบสถานะผิดพลาด', () async {
    
    // 1. สร้างบริการดึงราคา โดยยัด _FakeClient เข้าไป 
    // โดยแกล้งตั้งค่าสถานะ Response เป็น 503 (Service Unavailable / เซิร์ฟเวอร์ล่ม)
    final service = WongpanitPriceService(
      client: _FakeClient(http.Response('unavailable', 503)),
    );

    // 2. ใช้ expectLater ดักรอรับผลลัพธ์
    // คาดหวังว่า: เมื่อสั่งดึงราคาจากเว็บที่ล่ม (`service.fetchPrices()`) 
    // ระบบจะต้องโยน PriceFetchException ออกมาเตือนอย่างถูกต้อง (throwsA)
    await expectLater(
      service.fetchPrices(),
      throwsA(isA<PriceFetchException>()),
    );
  });
}