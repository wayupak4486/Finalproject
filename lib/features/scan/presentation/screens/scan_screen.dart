
//
//  ข้อควรเช็คก่อนไปสอบ (สำคัญมาก!): การส่ง imagePath: null ใช้ได้ก็ต่อเมื่อไฟล์อื่น "รับ null ได้"
//    1) scan_result_args.dart  → imagePath ต้องเป็น  String?  (มีเครื่องหมาย ? ต่อท้าย)
//    2) ResultCapturedImage    → ต้องไม่พังเวลา imagePath เป็น null (ถ้าไม่มีรูปให้ข้ามการวาดรูป)
//    3) HistoryRecordModel     → imagePath ต้องเป็น String? และตาราง History ใน SQLite ต้องยอมให้ค่าว่าง
//    4) AppRoutes.result       → ต้องมีชื่อเส้นทางนี้อยู่ใน router.dart
//    ถ้าตัวไหนไม่รับ null แอปจะขึ้น error แดงตอนคอมไพล์ หรือพังตอนกดบันทึก
// ###########################################################################

import 'package:flutter/material.dart'; // นำเข้าชุดเครื่องมือสร้างหน้าจอพื้นฐานของ Flutter
import 'package:image_picker/image_picker.dart'; // นำเข้าปลั๊กอินสำหรับเรียกใช้งานกล้องถ่ายรูปและคลังภาพในมือถือ

import '../../../../app/router.dart'; // นำเข้าระบบจัดการเส้นทาง (เอาไว้ใช้สั่งเปลี่ยนหน้าจอ)
import '../../../../services/ml/classifier_service.dart'; // นำเข้าบริการ AI สำหรับนำรูปภาพไปวิเคราะห์แยกแยะชนิดขยะ
import '../../../../services/ml/classification_result.dart'; // 🔧 1) [เพิ่มใหม่] นำเข้าคลาสโครงสร้างผลลัพธ์ของ AI (ClassificationResult) เพราะเราจะสร้างผลลัพธ์จำลองเองในฟังก์ชันใหม่
import '../../data/models/scan_result_args.dart'; // นำเข้าโครงสร้างกล่องข้อมูลสำหรับส่งข้ามหน้าจอ (รูปถ่าย และ ผล AI)
import '../widgets/result_screen_widgets.dart'; // 🔧 1) [เพิ่มใหม่] นำเข้าหน้าต่างสไลด์เลือกวัสดุ (MaterialPickerSheet) ที่มีอยู่แล้ว มาใช้ซ้ำ
import '../../../../core/constants/material_catalog.dart'; // 🔧 1) [เพิ่มใหม่] นำเข้าแคตตาล็อกข้อมูลขยะทั้งหมดในระบบ (ใช้ดึงรายชื่อวัสดุตัวแรกมาเป็นค่าเริ่มต้นของแผ่นเลือก)

// ===========================================================================
// 🛠️ โซนตั้งค่าขนาดและดีไซน์ (ScanStyle) สำหรับจัดระเบียบหน้าจอ
// ===========================================================================
class ScanStyle {
  ScanStyle._(); // ป้องกันไม่ให้มีการสร้างออบเจกต์ซ้ำซ้อนจากคลาสนี้ (ใช้เป็นแค่ที่เก็บค่าคงที่)

  static const double? titleFontSize =
      24; // ขนาดตัวหนังสือหัวข้อใหญ่ "เลือกแหล่งที่มาของภาพ"
  static const double? subtitleFontSize =
      14; // ขนาดตัวหนังสือคำอธิบายเล็กๆ ใต้หัวข้อ
  static const double buttonHeight =
      64; // ความสูงมาตรฐานของปุ่มกดทุกปุ่มในหน้านี้
  static const double buttonRadius = 22; // ความโค้งมนของมุมปุ่มกด
  static const double? buttonFontSize =
      18; // ขนาดตัวหนังสือด้านในปุ่มกดให้ตัวหนาใหญ่ชัดเจน
}

// ===========================================================================
// หน้าจอเลือกแหล่งที่มาของภาพ (StatefulWidget เพราะหน้าจอต้องเปลี่ยนสถานะตอนโหลด AI)
// ===========================================================================
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key}); // คอนสตรัคเตอร์ของหน้าจอ

  @override
  State<ScanScreen> createState() => _ScanScreenState(); // สร้าง State สำหรับเก็บตัวแปรและควบคุมการทำงานของหน้านี้
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _imagePicker =
      ImagePicker(); // สร้างตัวแปรสำหรับสั่งเปิดกล้องหรืออัลบั้มรูปภาพ

  bool _isPickingImage =
      false; // ตัวแปรเช็คสถานะว่า "กำลังประมวลผลรูปภาพอยู่หรือไม่?" (เริ่มต้นเป็น false)

  // ===========================================================================
  // 📸 ฟังก์ชันหลัก: ถ่ายรูป/เลือกรูป -> ส่งให้ AI วิเคราะห์ -> เปลี่ยนไปหน้าผลลัพธ์
  // (ฟังก์ชันเดิม ไม่ได้แก้อะไร)
  // ===========================================================================
  Future<void> _pickImage(ImageSource source) async {
    // รับค่าเข้ามาว่าจะใช้กล้อง (Camera) หรือคลังภาพ (Gallery)
    if (_isPickingImage)
      return; // ถ้าแอปกำลังโหลดวิเคราะห์อยู่ ให้ตัดจบการทำงานทันทีเพื่อกันกดซ้ำ

    setState(() {
      // สั่งให้หน้าจออัปเดตสถานะ
      _isPickingImage =
          true; // เปลี่ยนสถานะเป็น "กำลังโหลด" (เพื่อให้แถบโหลดแสดงขึ้นมา)
    });

    try {
      // เริ่มต้นบล็อกการทำงาน (เผื่อเกิดข้อผิดพลาดจะได้ดักจับได้)
      final XFile? pickedImage = await _imagePicker.pickImage(
        // สั่งเปิดกล้องหรือคลังภาพเพื่อเลือกรูป
        source: source, // แหล่งที่มาของรูป
        imageQuality:
            85, // บีบคุณภาพไฟล์รูปภาพเหลือ 85% เพื่อประหยัดหน่วยความจำ
        maxWidth:
            1280, // จำกัดความกว้างของรูปภาพไม่ให้ใหญ่เกินไป (ไม่เกิน 1280 พิกเซล)
      );

      if (!mounted)
        return; // เช็คว่าผู้ใช้กดปิดหน้านี้หนีไประหว่างถ่ายรูปหรือไม่ ถ้าปิดแล้วให้หยุดทำงาน

      if (pickedImage == null) {
        // ถ้าผู้ใช้กดยกเลิก ไม่ยอมถ่ายรูปหรือเลือกรูป
        return; // ออกจากฟังก์ชันไปเลย
      }

      // ส่งเส้นทางไฟล์ภาพ (pickedImage.path) ไปให้ AI ใน ClassifierService ทำนายผลชนิดขยะ
      final result = await ClassifierService.instance.classify(
        pickedImage.path,
      );

      if (!mounted) return; // เช็คสถานะหน้าจออีกรอบกันแอปพัง

      await Navigator.pushNamed(
        // สั่งเปลี่ยนหน้าจอไปยังหน้ายืนยันภาพ (ScanConfirm)
        context,
        AppRoutes.scanConfirm,
        arguments: ScanResultArgs(
          imagePath: pickedImage.path,
          result: result,
        ), // แนบรูปและผล AI ติดตัวไป
      );
    } catch (error) {
      // ถ้าเกิดข้อผิดพลาดระหว่างถ่ายรูปหรือ AI พัง
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        // โชว์แถบแจ้งเตือนสีดำด้านล่างจอ
        SnackBar(content: Text('ไม่สามารถวิเคราะห์ภาพได้: $error')),
      );
    } finally {
      // บล็อกนี้จะทำงาน "เสมอ" ไม่ว่าจะสำเร็จหรือพังก็ตาม
      if (mounted) {
        setState(() {
          _isPickingImage = false; // ปิดสถานะกำลังโหลด (ซ่อนแถบโหลดหมุนๆ)
        });
      }
    }
  }

  // ===========================================================================
  // 🔧 2) [ฟังก์ชันใหม่ ตัวเอกของฟีเจอร์นี้]
  // 📌 เปิดหน้าต่างเลือกประเภทวัสดุเองทันทีโดยไม่ต้องถ่ายรูป
  // ลำดับการทำงานมี 3 ขั้น: เลือกวัสดุ → สร้างผลลัพธ์จำลอง → ไปหน้าสรุปผล
  // ===========================================================================
  Future<void> _selectMaterialManually() async {
    // (async = ฟังก์ชันนี้มีการ "รอ" เช่น รอผู้ใช้เลือก จึงต้องมีคำว่า async และ Future)

    // ---------- ขั้น 1: เปิดแผ่นเลือกวัสดุ แล้วรอผู้ใช้จิ้มเลือก ----------
    // showModalBottomSheet = เปิดแผ่นที่สไลด์ขึ้นมาจากด้านล่างจอ
    // <String> = บอกว่าแผ่นนี้จะส่งค่ากลับมาเป็นข้อความ (ชื่อวัสดุ เช่น 'glass')
    // await = หยุดรอตรงนี้จนกว่าผู้ใช้จะเลือกหรือปิดแผ่น แล้วเอาค่าที่ได้ใส่ตัวแปร selectedLabel
    final selectedLabel = await showModalBottomSheet<String>(
      context: context, // บอกว่าให้เปิดแผ่นบนหน้าจอนี้
      isScrollControlled:
          true, // ยอมให้แผ่นสไลด์มีความสูงเพิ่มขึ้นได้ตามเนื้อหา
      showDragHandle:
          true, // แสดงขีดจับเล็กๆ ตรงกลางด้านบนของแผ่นสไลด์ (ไว้ดึงลงปิด)
      builder: (context) => MaterialPickerSheet(
        // MaterialPickerSheet = วิดเจ็ตแผ่นเลือกวัสดุที่ทีมเราสร้างไว้แล้วในไฟล์ result_screen_widgets.dart
        // (เรา "ยืมมาใช้ซ้ำ" จึงไม่ต้องเขียนหน้าเลือกวัสดุใหม่ ทำให้โค้ดสั้นและเสี่ยงพังน้อย)
        selectedLabel: MaterialCatalog
            .byLabel
            .keys
            .first, // วัสดุที่ถูกติ๊กไว้ตอนเปิดแผ่น = วัสดุตัวแรกในแคตตาล็อก
        aiLabel: '', // ช่อง "AI ทายว่า" ใส่ค่าว่าง เพราะรอบนี้ไม่ได้ใช้ AI
      ),
    );

    // ถ้าผู้ใช้ไม่ได้เลือกอะไร (ปัดแผ่นทิ้ง/กดยกเลิก ค่าจะเป็น null) หรือหน้าจอถูกปิดไปแล้ว (!mounted)
    // ให้หยุดทำงานทันที (return = ออกจากฟังก์ชัน) ไม่ต้องไปต่อ
    // (|| แปลว่า "หรือ" ถ้าเงื่อนไขใดเงื่อนไขหนึ่งเป็นจริง ก็เข้าไปทำ return)
    if (selectedLabel == null || !mounted) return;

    // ---------- ขั้น 2: สร้างผลลัพธ์ AI "จำลอง" (Dummy Result) ----------
    // ทำไมต้องสร้าง: หน้าสรุปผล (ResultScreen) ต้องการข้อมูลรูปแบบ "ผลจาก AI" เสมอ
    // เราเลยทำผลปลอมขึ้นมาให้ โดยใช้ชื่อวัสดุที่ผู้ใช้เลือกเอง
    // และตั้งความมั่นใจเป็น 100% (1.0) เพราะผู้ใช้เลือกเอง ถือว่าถูกต้องที่สุด
    final dummyResult = ClassificationResult(
      label: selectedLabel, // ชื่อวัสดุที่ผู้ใช้เลือกจากรายการ
      confidence: 1.0, // ความมั่นใจ 100% (1.0 = 100%, 0.5 = 50%)
      allScores: {}, // ตารางคะแนนของทุกคลาสเป็นค่าว่าง เพราะไม่ได้ผ่าน AI จริง
    );

    // ---------- ขั้น 3: พาผู้ใช้ไปหน้าสรุปผลทันที ----------
    // pushNamed = เปิดหน้าใหม่ตามชื่อเส้นทาง (AppRoutes.result)
    // arguments = กล่องข้อมูลที่แนบไปให้หน้าถัดไป (หน้า ResultScreen ไปรับด้วย ModalRoute...arguments)
    await Navigator.pushNamed(
      context,
      AppRoutes
          .result, // ไปยังหน้าสรุปผลและการประเมิน (ข้ามหน้ายืนยันรูปไปเลย เพราะไม่มีรูปให้ยืนยัน)
      arguments: ScanResultArgs(
        imagePath:
            null, // ไม่มีรูปภาพ เพราะผู้ใช้เลือกเองจากรายการ (ไฟล์ ScanResultArgs ต้องยอมให้เป็น null ได้ ดูหัวไฟล์)
        result: dummyResult, // ส่งผลลัพธ์จำลองติดตัวไปใช้งานต่อ
      ),
    );
  }

  // ===========================================================================
  // 🎨 โซนวาดหน้าจอหลัก (Build UI)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme; // ดึงชุดสีหลักของแอปมาใช้งาน

    return Scaffold(
      // โครงสร้างหน้าจอหลัก
      appBar: AppBar(title: const Text('สแกนวัสดุ')), // แถบหัวข้อด้านบนจอ
      body: SafeArea(
        // พื้นที่ปลอดภัย (ไม่ให้เนื้อหาไปชนขอบกล้องหรือรอยบากมือถือ)
        child: Padding(
          padding: const EdgeInsets.all(24), // เว้นขอบรอบทิศทาง 24 พิกเซล
          child: Column(
            // เรียงของจากบนลงล่าง
            children: [
              const Spacer(), // ดันเนื้อหาช่วงบนให้ลงมาอยู่ตรงกลางจอ

              Container(
                // กล่องวงกลมพื้นหลังสีเขียวอ่อนสำหรับใส่ไอคอนกล้อง
                width: 132,
                height: 132,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer, // สีพื้นหลังกล่อง
                  shape: BoxShape.circle, // ทำเป็นวงกลม
                ),
                child: Icon(
                  Icons.camera_alt_rounded, // ไอคอนรูปกล้องถ่ายรูป
                  size: 64,
                  color: colorScheme.primary, // สีไอคอน
                ),
              ),
              const SizedBox(height: 28), // เว้นระยะห่าง 28 พิกเซล

              Text(
                // หัวข้อหลักของหน้าจอ
                'เลือกแหล่งที่มาของภาพ',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: ScanStyle.titleFontSize,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                // ข้อความอธิบายใต้หัวข้อ (แก้ให้พูดถึงตัวเลือกใหม่ด้วย)
                'ถ่ายภาพ เลือกจากคลังภาพ หรือเลือกประเภทวัสดุด้วยตนเอง',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: ScanStyle.subtitleFontSize,
                ),
              ),
              const Spacer(), // ดันปุ่มกดทั้งหมดลงไปชิดขอบด้านล่าง
              // ปุ่มที่ 1: ปุ่มสำหรับเปิดกล้องถ่ายภาพ
              _ImageSourceButton(
                label: 'ถ่ายภาพ',
                icon: Icons.camera_alt_rounded,
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(
                        ImageSource.camera,
                      ), // ถ้ากำลังโหลดอยู่ให้กดไม่ได้ (null = ปุ่มเทา กดไม่ได้)
              ),
              const SizedBox(height: 16),

              // ปุ่มที่ 2: ปุ่มสำหรับเลือกรูปจากคลังภาพในมือถือ
              _ImageSourceButton(
                label: 'เลือกจากคลังภาพ',
                icon: Icons.photo_library_rounded,
                onPressed: _isPickingImage
                    ? null
                    : () => _pickImage(
                        ImageSource.gallery,
                      ), // ถ้ากำลังโหลดอยู่ให้กดไม่ได้
              ),
              const SizedBox(height: 16),

              // 🔧 3) [ปุ่มใหม่] ปุ่มที่ 3: เลือกประเภทวัสดุเองทันทีโดยไม่ต้องถ่ายรูป
              // OutlinedButton.icon = ปุ่มแบบมีแค่ขอบ (ไม่ทึบ) พร้อมไอคอน จะได้ดูต่างจากปุ่มสองปุ่มด้านบน
              OutlinedButton.icon(
                // onPressed = สิ่งที่จะทำเมื่อกดปุ่ม
                // ถ้ากำลังโหลดอยู่ (_isPickingImage เป็น true) ให้เป็น null = กดไม่ได้
                // ถ้าไม่ได้โหลด ให้เรียกฟังก์ชัน _selectMaterialManually (ตัวที่เราสร้างไว้ด้านบน)
                onPressed: _isPickingImage ? null : _selectMaterialManually,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(
                    ScanStyle.buttonHeight,
                  ), // บังคับความสูงปุ่มเท่ากับปุ่มอื่น (กว้างเต็มจอ สูง 64)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      ScanStyle.buttonRadius,
                    ), // มุมโค้งมนของปุ่ม (เท่ากับปุ่มอื่น)
                  ),
                  side: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ), // ขอบเส้นสีหลักหนา 2 ให้ดูเด่นชัด
                  textStyle: TextStyle(
                    fontSize: ScanStyle
                        .buttonFontSize, // ขนาดตัวหนังสือเท่ากับปุ่มอื่น
                    fontWeight: FontWeight.w900, // ตัวหนังสือหนาพิเศษ
                  ),
                ),
                icon: const Icon(
                  Icons.list_alt_rounded,
                  size: 28,
                ), // ไอคอนรูปรายการลิสต์ ขนาด 28
                label: const Text(
                  'เลือกประเภทวัสดุเอง',
                ), // ข้อความบนปุ่ม (อยากเปลี่ยนคำบนปุ่ม แก้ตรงนี้)
              ),
              const SizedBox(height: 20),

              // ถ้าสถานะ _isPickingImage เป็น true (กำลังโหลด AI) ให้โชว์แถบวิ่งโหลดด้านล่าง
              if (_isPickingImage) ...[
                const LinearProgressIndicator(), // แถบโหลดวิ่งๆ
                const SizedBox(height: 8),
                Text(
                  'กำลังวิเคราะห์ภาพ...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนวิดเจ็ตปุ่มกดแบบกำหนดเอง (ใช้สำหรับปุ่มถ่ายภาพและเลือกจากคลังภาพ)
// (ไม่ได้แก้อะไร)
// ===========================================================================
class _ImageSourceButton extends StatelessWidget {
  const _ImageSourceButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label; // ข้อความที่จะแสดงบนปุ่ม
  final IconData icon; // ไอคอนที่จะแสดงบนปุ่ม
  final VoidCallback?
  onPressed; // ฟังก์ชันที่จะให้ทำงานเมื่อกดปุ่ม (เป็น null ได้ = ปุ่มกดไม่ได้)

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      // ปุ่มแบบทึบสีเต็ม พร้อมไอคอน
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(
          ScanStyle.buttonHeight,
        ), // ความสูงปุ่ม
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ScanStyle.buttonRadius,
          ), // ความโค้งมนขอบปุ่ม
        ),
        textStyle: TextStyle(
          fontSize: ScanStyle.buttonFontSize,
          fontWeight: FontWeight.w900, // ตัวหนังสือหนา
        ),
      ),
      icon: Icon(icon, size: 28), // วาดไอคอน
      label: Text(label), // วาดข้อความ
    );
  }
}
