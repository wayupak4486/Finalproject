// ==============================================================================
// ไฟล์ UI สำหรับโชว์สถานะกำลังโหลด (Loading State)
// ==============================================================================
import 'package:flutter/material.dart'; //

class LoadingView extends StatelessWidget { //
  // รับข้อความมาแสดง ถ้าไม่ส่งมาจะใช้คำว่า 'กำลังโหลด...' เป็นค่าตั้งต้น
  const LoadingView({super.key, this.message = 'กำลังโหลด...'}); //[cite: 18]

  final String message; //[cite: 18]

  @override
  Widget build(BuildContext context) { //[cite: 18]
    // วางกล่องทั้งหมดไว้ตรงกลางหน้าจอพอดี
    return Center( //[cite: 18]
      child: Column( //[cite: 18]
        mainAxisSize: MainAxisSize.min, // ให้ Column สูงเท่าที่จำเป็น ป้องกันการยืดเต็มจอ[cite: 18]
        children: [ //[cite: 18]
          const CircularProgressIndicator(), // ไอคอนวงกลมหมุนๆ[cite: 18]
          const SizedBox(height: 16), // เว้นช่องว่างระหว่างวงกลมกับข้อความ 16 พิกเซล[cite: 18]
          Text(message), // แสดงข้อความ (เช่น 'กำลังวิเคราะห์ AI...')[cite: 18]
        ],
      ),
    );
  }
}