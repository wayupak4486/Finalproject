import 'package:flutter/material.dart'; // ชุดเครื่องมือวาดหน้าจอ

import '../../../../app/router.dart'; // เครื่องมือเปลี่ยนหน้า
import '../../../../core/constants/app_constants.dart'; // ค่าคงที่ของแอป (เช่น เกณฑ์ความมั่นใจ AI)
import '../../../../core/constants/material_catalog.dart'; // แคตตาล็อกข้อมูลขยะ
import '../../data/models/scan_result_args.dart'; // โครงสร้างรับส่งข้อมูล
import '../widgets/result_screen_widgets.dart'; // นำเข้าชิ้นส่วน UI ที่เราสร้างไว้ในไฟล์ widgets

// ===========================================================================
// หน้าจอยืนยันผลสแกน (StatelessWidget เพราะไม่มีการพิมพ์หรือโหลดอะไร โชว์แค่ข้อมูล)
// ===========================================================================
class ScanConfirmScreen extends StatelessWidget {
  const ScanConfirmScreen({super.key}); // คอนสตรัคเตอร์

  @override
  Widget build(BuildContext context) { // ฟังก์ชันวาดหน้าจอ
    // 1. รับข้อมูลที่ส่งข้ามหน้าจอมา (รับรูปภาพ และ ข้อมูลที่ AI ทาย)
    final args = ModalRoute.of(context)!.settings.arguments as ScanResultArgs;
    
    // 2. เอาชื่อที่ AI ทาย ไปค้นหาในแคตตาล็อก เพื่อดึงข้อมูลเชิงลึก (เช่น หมวดหมู่, ขายได้ไหม)
    final materialInfo = MaterialCatalog.lookup(args.result.label);
    
    // 3. ตรวจสอบว่าความมั่นใจของ AI (Confidence) ต่ำกว่าเกณฑ์ที่ตั้งไว้ใน AppConstants หรือไม่
    final isLowConfidence = args.result.confidence < AppConstants.lowConfidenceThreshold;

    return Scaffold( // โครงร่างหน้าจอ
      appBar: AppBar(title: const Text('ผลการวิเคราะห์')), // แถบชื่อหน้า
      body: SafeArea( // พื้นที่ปลอดภัย
        child: Padding( // เว้นระยะขอบ
          padding: const EdgeInsets.all(20), // รอบด้าน 20 พิกเซล
          child: Column( // จัดเรียงบนลงล่าง
            children: [
              // Expanded ตรงนี้จะกินพื้นที่ว่างทั้งหมด ทำให้ปุ่มข้างล่างโดนดันไปติดขอบจอล่างสุด
              Expanded(
                child: ListView( // กล่องที่ใช้นิ้วเลื่อนขึ้นลงได้
                  children: [
                    // ชิ้นส่วนที่ 1: วาดรูปภาพที่ถ่ายมา
                    ResultCapturedImage(imagePath: args.imagePath),
                    const SizedBox(height: 16), // เว้นระยะ
                    
                    // ชิ้นส่วนที่ 2: วาดการ์ดแสดงผล AI
                    ResultInfoCard(
                      title: 'ผลการวิเคราะห์', // หัวข้อการ์ด
                      children: [ // เนื้อหาข้างใน
                        // บรรทัด 1: ชื่อวัสดุที่ AI ทาย
                        ResultKeyValueRow(
                          label: 'ผลทำนายจาก',
                          value: materialInfo.displayName,
                        ),
                        // บรรทัด 2: เปอร์เซ็นต์ความมั่นใจ (แปลงทศนิยมเป็นเปอร์เซ็นต์โชว์ 1 ตำแหน่ง)
                        ResultKeyValueRow(
                          label: 'ความมั่นใจ',
                          value: '${(args.result.confidence * 100).toStringAsFixed(1)}%',
                        ),
                        // บรรทัด 3: ถ้าความมั่นใจต่ำ (isLowConfidence = true) ให้โชว์คำเตือน
                        if (isLowConfidence) ...[
                          const SizedBox(height: 8),
                          const ResultWarningText(
                            'ความมั่นใจต่ำ — กรุณาตรวจสอบวัสดุในขั้นตอนถัดไป',
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16), // เว้นระยะก่อนถึงปุ่ม
              
              // โซนปุ่มด้านล่างสุด (แบ่งครึ่งซ้ายขวา)
              Row(
                children: [
                  // ปุ่มซ้าย: "ย้อนกลับ"
                  Expanded( // ขยายปุ่มให้เต็มพื้นที่ครึ่งนึง
                    child: SecondaryActionButton( // ใช้ปุ่มขอบโปร่งใส
                      label: 'ย้อนกลับ', // ชื่อปุ่ม
                      // คำสั่ง Navigator.pop จะปิดหน้าต่างนี้ทิ้ง ทำให้กลับไปหน้าถ่ายรูปอัตโนมัติ
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16), // เว้นตรงกลางระหว่างปุ่ม 16 พิกเซล
                  
                  // ปุ่มขวา: "ถัดไป"
                  Expanded( // ขยายปุ่มให้เต็มพื้นที่อีกครึ่ง
                    child: PrimaryActionButton( // ใช้ปุ่มทึบสีหลัก
                      label: 'ถัดไป', // ชื่อปุ่ม
                      // คำสั่ง Navigator.pushNamed จะเปิดหน้า ResultScreen (เพื่อกรอกน้ำหนัก)
                      onPressed: () => Navigator.pushNamed(
                        context, // อ้างอิงหน้าปัจจุบัน
                        AppRoutes.result, // ชื่อเส้นทางของหน้าถัดไป
                        arguments: args, // โยนข้อมูลรูป+AI ส่งไปหน้าถัดไปด้วย
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}