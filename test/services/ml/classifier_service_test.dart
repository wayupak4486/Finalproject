import 'dart:io'; // นำเข้าเครื่องมือจัดการไฟล์และโฟลเดอร์ในเครื่อง (Directory, File)

import 'package:flutter_test/flutter_test.dart'; // นำเข้าชุดเครื่องมือทำ Unit Test ของ Flutter
import 'package:lastboss/services/ml/classifier_service.dart'; // นำเข้าสมองกล AI ของเรา

// ===========================================================================
// ฟังก์ชัน main() สำหรับรันชุดทดสอบ
// ===========================================================================
void main() {
  
  // 💡 สร้างเคสทดสอบการจัดการไฟล์ภาพเสีย
  test('ไฟล์ภาพที่อ่านไม่ได้ส่งข้อผิดพลาดก่อนเปิดโมเดล', () async {
    
    // ---------- 1. เตรียมไฟล์ปลอมจำลอง (Arrange) ----------
    
    // สร้างโฟลเดอร์ชั่วคราวในระบบ โดยขึ้นต้นชื่อว่า 'godscan_test_'
    final directory = await Directory.systemTemp.createTemp('godscan_test_');
    
    // สร้างไฟล์ชื่อ 'invalid.jpg' เอาไว้ข้างในโฟลเดอร์ชั่วคราว
    final file = File('${directory.path}${Platform.pathSeparator}invalid.jpg');
    
    // เขียนข้อความตัวหนังสือดิบๆ ลงไปในไฟล์ (แกล้งหลอกว่าเป็นไฟล์รูปภาพ แต่ความจริงไม่ใช่รูป!)
    await file.writeAsString('not an image');

    // 💡 คำสั่งทำความสะอาดอัตโนมัติ (Teardown)
    // เมื่อเทสนี้ทำงานเสร็จ (ไม่ว่าจะผ่านหรือพัง) ให้สั่งลบโฟลเดอร์ชั่วคราวนี้ทิ้งพร้อมไฟล์ข้างในทันที (recursive: true)
    // เพื่อไม่ให้ไฟล์ขยะตกค้างรกหน่วยความจำเครื่อง
    addTearDown(() => directory.delete(recursive: true));

    // ---------- 2 & 3. สั่งรันและดักจับ Error (Act & Assert) ----------
    
    // 💡 expectLater: ใช้สำหรับการทดสอบฟังก์ชัน Asynchronous แบบรอผลลัพธ์ (`Future`)
    // เราสั่งให้ AI เข้าไปวิเคราะห์ไฟล์ปลอม (file.path)
    // และเรา "คาดหวังว่า" มันจะต้องโยน Error ออกมา (throwsA) โดย Error นั้นต้องเป็นประเภท StateError (isA<StateError>())
    await expectLater(
      ClassifierService.instance.classify(file.path),
      throwsA(isA<StateError>()),
    );
  });
}