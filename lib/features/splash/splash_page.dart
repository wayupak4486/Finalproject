import 'dart:async'; // นำเข้าชุดเครื่องมือ 'async' เพื่อใช้งาน Timer (นาฬิกาตั้งเวลา)
import 'package:flutter/material.dart'; // นำเข้าชุดเครื่องมือวาด UI ของ Flutter

// ===========================================================================
// คลาสหน้าจอ Splash Screen (หน้าโหลดเข้าแอป)
// ทำไมต้องเป็น StatefulWidget? -> เพราะหน้านี้มีวงจรชีวิต (Lifecycle - initState)
// ที่ต้องสั่งให้นาฬิกานับถอยหลังทำงานทันทีที่หน้าจอถูกสร้างขึ้น
// ===========================================================================
class CustomSplashScreen extends StatefulWidget {
  // Constructor: ฟังก์ชันสร้างหน้าจอ
  const CustomSplashScreen({super.key});

  @override
  // สร้าง State เพื่อเก็บสถานะและการทำงานของหน้าจอนี้
  State<CustomSplashScreen> createState() => _CustomSplashScreenState();
}

class _CustomSplashScreenState extends State<CustomSplashScreen> {
  
  // ===========================================================================
  // initState: ฟังก์ชันวงจรชีวิต (Lifecycle)
  // จะทำงานอัตโนมัติ "ครั้งแรก และครั้งเดียว" ก่อนที่หน้าจอจะถูกวาด
  // ===========================================================================
  @override
  void initState() {
    super.initState(); // บังคับเรียก initState ของคลาสแม่ (ห้ามลืม)
    
    // 💡 สร้างนาฬิกานับถอยหลัง (Timer)
    // Parameter 1: ระยะเวลา (Duration) ในที่นี้คือ 2 วินาที
    // Parameter 2: ฟังก์ชัน (Callback) ที่จะให้ทำงานเมื่อนับถอยหลังครบเวลา
    Timer(const Duration(seconds: 2), () {
      
      // 💡 [จุดที่ผมเติมให้] คำสั่งเปลี่ยนหน้าจอ (Routing)
      // Navigator.pushReplacement = สั่งเปิดหน้าใหม่ (เช่น /home) และ "ทำลาย" หน้านี้ทิ้งไปซะ!
      // เพื่อป้องกันไม่ให้ผู้ใช้กดปุ่ม ย้อนกลับ (Back) กลับมาเจอหน้าโหลดนี้ได้อีก
      Navigator.pushReplacementNamed(context, '/home'); 
      // (หมายเหตุ: ถ้าในโปรเจกต์ใช้ AppRoutes.home ก็เปลี่ยน '/home' เป็น AppRoutes.home ได้เลยครับ)
      
    });
  }

  // ===========================================================================
  // build: ฟังก์ชันบังคับที่มีหน้าที่ "วาดหน้าจอ" (UI)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // Scaffold = โครงกระดูกหลักของหน้าจอแอป
    return Scaffold(
      backgroundColor: Colors.white, // ตั้งค่าสีพื้นหลังของทั้งหน้าจอเป็นสีขาว
      
      // Center = วิดเจ็ตที่ทำหน้าที่จัดให้ของข้างใน (child) อยู่กึ่งกลางหน้าจอพอดีเป๊ะ
      body: Center(
        
        // Image.asset = ดึงรูปภาพจากในโฟลเดอร์ของโปรเจกต์มาแสดง
        child: Image.asset(
          'assets/images/logo.png', // เส้นทางไฟล์รูปภาพ (ต้องตรงกับที่ตั้งไว้ใน pubspec.yaml)
          
          width: 280, // กำหนดความกว้างของรูปภาพเป็น 280 พิกเซล
          height: 280, // กำหนดความสูงของรูปภาพเป็น 280 พิกเซล (บังคับให้เป็นสี่เหลี่ยมจัตุรัส)
        ),
      ),
    );
  }
}