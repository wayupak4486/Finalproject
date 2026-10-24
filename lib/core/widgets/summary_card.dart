// ==============================================================================
// ส่วนที่ 1: นำเข้าแพ็กเกจ
// ==============================================================================
import 'package:flutter/material.dart'; //

// ==============================================================================
// ส่วนที่ 2: คลาส SummaryCard (แม่แบบการ์ดสถิติ)
// ==============================================================================
class SummaryCard extends StatelessWidget { //
  
  // Constructor: บังคับรับค่า icon, title, value เสมอ (ด้วยคำว่า required)
  const SummaryCard({
    required this.icon, //
    required this.title, //
    required this.value, //
    super.key,
  });

  // ตัวแปรรับข้อมูลจากหน้าจออื่น
  final IconData icon; //[cite: 19]
  final String title; //[cite: 19]
  final String value; //[cite: 19]

  // ----------------------------------------------------------------------------
  // กลุ่มตั้งค่าขนาด (อ้างอิงตามคอมเมนต์ //การ์ดเทา หน้าสถิติ)
  // ----------------------------------------------------------------------------
  static const double iconSize = 28; // ขนาดไอคอน[cite: 19]
  static const double valueFontSize = 22; // ตัวเลขใหญ่[cite: 19]
  static const double titleFontSize = 18; // ข้อความเล็ก[cite: 19]
  static const double cardPadding = 16; // ระยะห่างขอบในการ์ด[cite: 19]

  // ----------------------------------------------------------------------------
  // ฟังก์ชัน build: ทำหน้าที่วาดการ์ด
  // ----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) { //[cite: 19]
    // ดึงชุดสี (Color Scheme) ของแอปพลิเคชันมาจาก Theme หลัก (ที่เราเคยดูในไฟล์ theme.dart)
    final colorScheme = Theme.of(context).colorScheme; //[cite: 19]

    // 1. สร้างกล่อง Card (เป็นกรอบสี่เหลี่ยมที่มีพื้นหลังและมุมโค้งนิดๆ)
    return Card( //[cite: 19]
      
      // 2. Padding: เว้นระยะขอบด้านในของการ์ดทุกทิศทางด้วยค่า cardPadding (16 พิกเซล)
      child: Padding( //[cite: 19]
        padding: const EdgeInsets.all(cardPadding), //[cite: 19]
        
        // 3. Column: จัดเรียงเนื้อหาจากบนลงล่าง
        child: Column( //[cite: 19]
          // บังคับให้ของทุกชิ้นใน Column ชิดซ้าย (start)
          crossAxisAlignment: CrossAxisAlignment.start, //[cite: 19]
          
          children: [
            // ชั้นที่ 1: วาดไอคอน โดยดึงสี primary (เช่น สีเขียวหลักของแอป) มาจาก Theme
            Icon(icon, color: colorScheme.primary, size: iconSize), //[cite: 19]
            
            // ช่องว่างคั่น 12 พิกเซล
            const SizedBox(height: 12), //[cite: 19]
            
            // ชั้นที่ 2: วาดตัวเลขข้อมูลหลัก (เช่น 500 บาท)
            Text(
              value, //[cite: 19]
              // ดึงสไตล์ตัวอักษร titleLarge จาก Theme มาปรับปรุง (copyWith) ให้ตัวหนาและมีขนาดตามที่ตั้งไว้
              style: Theme.of(context).textTheme.titleLarge?.copyWith( //[cite: 19]
                fontWeight: FontWeight.bold, //[cite: 19]
                fontSize: valueFontSize, //[cite: 19]
              ),
            ),
            
            // ช่องว่างคั่น 4 พิกเซล
            const SizedBox(height: 4), //[cite: 19]
            
            // ชั้นที่ 3: วาดข้อความอธิบายใต้ตัวเลข
            Text(
              title, //[cite: 19]
              // ดึงสไตล์ bodySmall มาปรับขนาดตามตัวแปร titleFontSize
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: titleFontSize), //[cite: 19]
            ),
          ],
        ),
      ),
    );
  }
}