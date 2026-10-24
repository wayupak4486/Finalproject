import 'dart:io'; // นำเข้าเครื่องมือจัดการไฟล์ (เอาไว้เช็คว่ารูปภาพมีอยู่จริงไหมในเครื่อง)

import 'package:flutter/material.dart'; // นำเข้าชุดเครื่องมือสร้าง UI ของ Flutter

import '../../../../core/constants/material_catalog.dart'; // นำเข้าแคตตาล็อกข้อมูลขยะ

// ===========================================================================
// 🛠️ โซนตั้งค่าขนาด (ResultStyle) 🛠️
// ใช้ควบคุมขนาดของชิ้นส่วนต่างๆ ในหน้าผลลัพธ์
// ===========================================================================
class ResultStyle {
  ResultStyle._(); // ป้องกันการสร้างออบเจกต์

  // ขนาดความสูงและความโค้งของปุ่มหลัก (เช่น ถัดไป, บันทึกข้อมูล, ย้อนกลับ)
  static const double actionButtonHeight = 56; // ความสูงปุ่ม
  static const double actionButtonRadius = 18; // ความโค้งปุ่ม

  // ขนาดตัวอักษรของการ์ดข้อมูล (ปรับแก้ตรงนี้ได้เลยถ้าอยากให้ใหญ่ขึ้น)
  static const double? cardTitleFontSize =
      24; // หัวข้อการ์ด (เช่น 'ผลการวิเคราะห์')
  static const double? rowLabelFontSize = 18; // หัวข้อในแถว (เช่น 'ผลทำนายจาก')
  static const double? rowValueFontSize =
      18; // ค่าในแถว (เช่น 'ขวดพลาสติก PET')
  static const double? actionButtonFontSize = 20;
}

// ===========================================================================
// ชิ้นส่วนที่ 1: กล่องแสดงรูปภาพที่ถ่ายมา (หรือโชว์ไอคอนถ้าผู้ใช้เลือกวัสดุเองโดยไม่ถ่ายรูป)
// ===========================================================================
class ResultCapturedImage extends StatelessWidget {
  const ResultCapturedImage({
    required this.imagePath, // รับเส้นทางไฟล์ภาพมา (ถ้าเลือกเองจากรายการค่าจะเป็น null)
    super.key,
  });
  final String?
  imagePath; // ตัวแปรเก็บที่อยู่ไฟล์ (เป็น nullable String เพราะอาจเป็น null ได้)

  @override
  Widget build(BuildContext context) {
    // 💡 เช็คเงื่อนไขพิเศษ: ถ้า imagePath เป็น null แสดงว่าผู้ใช้ "เลือกประเภทวัสดุเอง" โดยไม่ได้ถ่ายรูปมา
    if (imagePath == null) {
      return Container(
        height: 160, // กำหนดความสูงของกล่องให้พอดี ไม่สูงเท่ารูปถ่ายจริง
        width: double.infinity, // ขยายความกว้างเต็มจอ
        decoration: BoxDecoration(
          color: Colors
              .green
              .shade100, // เทสีพื้นหลังเป็นสีเขียวพาสเทลอ่อนๆ สบายตา สื่อถึงโหมดเลือกเอง
          borderRadius: BorderRadius.circular(
            24,
          ), // ทำมุมโค้งมน 24 พิกเซลให้กลมกลืนกับการ์ดอื่น
          border: Border.all(
            color: Colors.green.shade300,
            width: 1.5,
          ), // วาดเส้นขอบสีเขียวอ่อนรอบกล่อง
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // จัดไอคอนและข้อให้อยู่ตรงกลางกล่องพอดี
          children: const [
            Icon(
              Icons.list_alt_rounded, // ไอคอนรูปกระดาษรายการ (List)
              size: 52, // ขนาดไอคอนใหญ่กำลังดี
              color: Color(0xFF1F7A35), // สีไอคอนเป็นสีเขียวเข้มเข้ากับธีมแอป
            ),
            SizedBox(height: 8), // เว้นระยะห่างระหว่างไอคอนกับตัวหนังสือ
            Text(
              'เลือกประเภทวัสดุด้วยตนเอง', // ข้อความบอกผู้ใช้
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold, // ตัวหนังสือหนา
                color: Color(0xFF1F7A35), // ตัวหนังสือสีเขียวเข้ม
              ),
            ),
          ],
        ),
      );
    }

    // เช็คว่า imagePath ไม่ใช่ค่าว่าง และ ไฟล์รูปภาพนั้นมีอยู่จริงในเครื่องมือถือจริงๆ
    final bool hasImage = File(imagePath!).existsSync();

    if (!hasImage) {
      // ถ้าไม่มีไฟล์รูปภาพอยู่จริงในเครื่อง
      return AspectRatio(
        aspectRatio: 16 / 10, // สัดส่วนแนวนอน
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest, // สีพื้นหลังเทาๆ
            borderRadius: BorderRadius.circular(24), // มุมโค้ง
          ),
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              size: 64,
            ), // โชว์ไอคอนรูปภาพโปร่งใสตรงกลางแทน
          ),
        ),
      );
    }

    // กรณีปกติ: ถ้ามีรูปภาพถ่ายจริงจากการสแกน
    return ClipRRect(
      borderRadius: BorderRadius.circular(24), // กำหนดความโค้งขอบรูป 24 พิกเซล
      child: Image.file(
        File(imagePath!), // ดึงไฟล์ภาพจากที่อยู่ในมือถือมาแสดง
        height: 240, // บังคับความสูงรูป 240 พิกเซล
        width: double.infinity, // ความกว้างขยายเต็มจอ
        fit: BoxFit.cover, // ซูมรูปให้เต็มกรอบพอดีโดยไม่ให้ภาพเบี้ยว
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 2: กรอบการ์ดสีขาวสำหรับใส่ข้อมูล (ใช้สร้างเป็นพื้นหลัง)
// ===========================================================================
class ResultInfoCard extends StatelessWidget {
  const ResultInfoCard({
    required this.title,
    required this.children,
    super.key,
  });
  final String title; // ชื่อหัวข้อการ์ด
  final List<Widget> children; // ชิ้นส่วนเนื้อหาที่จะเอามายัดใส่ในการ์ด

  @override
  Widget build(BuildContext context) {
    return Card(
      // วิดเจ็ตการ์ด (จะมีเงาบางๆ และพื้นหลังสีขาวโดยอัตโนมัติ)
      child: Padding(
        // เว้นระยะห่างด้านใน
        padding: const EdgeInsets.all(16), // เว้น 16 พิกเซลทุกด้าน
        child: Column(
          // เรียงของจากบนลงล่าง
          crossAxisAlignment: CrossAxisAlignment.start, // ให้ทุกอย่างชิดซ้าย
          children: [
            // ของข้างใน
            Text(
              // บรรทัดแรกคือหัวข้อการ์ด
              title, // โชว์ข้อความหัวข้อ
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold, // ตัวหนา
                fontSize:
                    ResultStyle.cardTitleFontSize, // ดึงขนาดฟอนต์จากค่าคงที่
              ),
            ),
            const SizedBox(height: 12), // เว้นระยะห่างใต้หัวข้อ
            ...children, // กระจาย (Spread) วิดเจ็ตที่รับมาให้มาเรียงต่อกันตรงนี้
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 3: แถวข้อมูล ซ้าย-ขวา (เช่น "น้ำหนัก" อยู่ซ้าย "2 กก." อยู่ขวา)
// ===========================================================================
class ResultKeyValueRow extends StatelessWidget {
  const ResultKeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
    super.key,
  });
  final String label; // ข้อความฝั่งซ้าย
  final String value; // ข้อความฝั่งขวา
  final Color? valueColor; // สีข้อความฝั่งขวา (ใส่หรือไม่ใส่ก็ได้)

  @override
  Widget build(BuildContext context) {
    return Padding(
      // เว้นระยะ
      padding: const EdgeInsets.only(bottom: 8), // ห่างด้านล่าง 8 พิกเซล
      child: Row(
        // จัดเรียงแนวนอน ซ้ายไปขวา
        children: [
          Expanded(
            // ดันให้ฝั่งซ้ายกินพื้นที่กว้างที่สุดเท่าที่ทำได้
            child: Text(
              label,
              style: TextStyle(fontSize: ResultStyle.rowLabelFontSize),
            ), // แสดงข้อความฝั่งซ้าย
          ),
          Text(
            // แสดงข้อความฝั่งขวา
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold, // ตัวหนา
              color: valueColor, // ใส่สี (ถ้ามี)
              fontSize: ResultStyle.rowValueFontSize, // ดึงขนาดฟอนต์
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 4: ข้อความแบบมีจุด Bullet (เอาไว้โชว์เคล็ดลับ)
// ===========================================================================
class ResultTipText extends StatelessWidget {
  const ResultTipText(this.text, {super.key}); // รับข้อความมา
  final String text; // ตัวแปรเก็บข้อความ

  @override
  Widget build(BuildContext context) {
    return Padding(
      // เว้นระยะ
      padding: const EdgeInsets.only(bottom: 6), // ห่างล่าง 6 พิกเซล
      child: Row(
        // จัดแนวนอน
        crossAxisAlignment: CrossAxisAlignment.start, // ให้ข้อความชิดด้านบน
        children: [
          const Text('• '), // วาดจุด Bullet
          Expanded(
            child: Text(text),
          ), // ข้อความเคล็ดลับ (ใช้ Expanded เผื่อข้อความยาวจะได้ตัดขึ้นบรรทัดใหม่ได้)
        ],
      ),
    );
  }
}

// ===========================================================================
// 🌟 ชิ้นส่วนที่ 5: ช่องกดเลือก/แก้ไขวัสดุ (ไฮไลท์ UI เด็ด!) 🌟
// ทำพื้นหลังให้เป็นสีเขียวอ่อน ขอบเข้ม มีไอคอนดินสอ เพื่อให้ผู้ใช้รู้ว่ากดแก้ไขได้
// ===========================================================================
class MaterialReviewField extends StatelessWidget {
  const MaterialReviewField({
    required this.selectedInfo,
    required this.onTap,
    super.key,
  });
  final MaterialInfo selectedInfo; // รับข้อมูลวัสดุปัจจุบัน
  final VoidCallback onTap; // รับคำสั่งเมื่อโดนกด

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // ทำให้กล่องนี้สามารถเอานิ้วกดได้ และมีเอฟเฟกต์กระเพื่อม (Ripple)
      borderRadius: BorderRadius.circular(12), // ลบมุมเอฟเฟกต์กระเพื่อมให้โค้ง
      onTap: onTap, // เมื่อโดนกด ให้รันคำสั่งที่รับมา
      child: InputDecorator(
        // วิดเจ็ตแต่งกล่องข้อความให้หน้าตาเหมือนฟอร์มกรอกข้อมูล
        decoration: InputDecoration(
          // ตกแต่งกล่อง
          labelText: 'ตรวจสอบ / แก้ไขวัสดุ', // ข้อความลอยๆ ด้านบนขอบ
          filled: true, // สั่งให้เทสีพื้นหลัง
          fillColor: Colors.green.shade50, // ใช้สีพื้นหลังเป็นสีเขียวสว่างสุดๆ
          border: OutlineInputBorder(
            // ตั้งค่าขอบแบบโค้ง
            borderRadius: BorderRadius.circular(12), // โค้ง 12
            borderSide: BorderSide(color: Colors.green.shade300), // สีขอบ
          ),
          enabledBorder: OutlineInputBorder(
            // ตั้งค่าขอบเวลาไม่ได้กดพิมพ์
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.green.shade400,
              width: 1.5,
            ), // ขอบสีเขียวหนา 1.5
          ),
        ),
        child: Row(
          // จัดเรียงเนื้อหาข้างในซ้ายไปขวา
          children: [
            Icon(
              Icons.recycling_rounded,
              size: 24,
              color: Colors.green.shade700,
            ), // ไอคอนรีไซเคิลสีเขียวเข้ม
            const SizedBox(width: 10), // เว้นระยะ 10
            Expanded(
              // ให้ชื่อวัสดุกินพื้นที่ตรงกลางให้หมด
              child: Text(
                selectedInfo.displayName, // โชว์ชื่อวัสดุ
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, // ตัวหนา
                  color: Colors.green.shade900, // ตัวหนังสือสีเขียวเข้มมาก
                ),
              ),
            ),
            Icon(
              Icons.edit_rounded,
              color: Colors.green.shade700,
              size: 20,
            ), // ไอคอนรูปดินสอ (Edit) สื่อว่าแก้ได้
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 6: แผ่นหน้าต่างสไลด์ (Bottom Sheet) ให้กดเลือกวัสดุใหม่
// ===========================================================================
class MaterialPickerSheet extends StatelessWidget {
  const MaterialPickerSheet({
    required this.selectedLabel,
    required this.aiLabel,
    super.key,
  });
  final String selectedLabel; // วัสดุที่เลือกอยู่ปัจจุบัน
  final String aiLabel; // วัสดุที่ AI ทายไว้ตอนแรก

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // ป้องกันไม่ให้แผ่นไปทับขอบจอล่าง
      child: Padding(
        // เว้นระยะห่างด้านใน
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12), // ซ้าย บน ขวา ล่าง
        child: Column(
          // เรียงบนลงล่าง
          mainAxisSize: MainAxisSize.min, // ให้ความสูงของกล่องหดพอดีกับเนื้อหา
          crossAxisAlignment: CrossAxisAlignment.start, // ชิดซ้าย
          children: [
            Text(
              // หัวข้อแผ่นสไลด์
              'เลือกวัสดุที่ถูกต้อง',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              // คำอธิบาย
              'หากผลวิเคราะห์ไม่ตรงกับวัสดุจริง เลือกรายการที่ถูกต้องได้ที่นี่',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            // วนลูป (for) สร้างรายการวัสดุทุกชนิดที่มีในระบบ
            for (final entry in MaterialCatalog.byLabel.entries)
              _MaterialOptionTile(
                // เรียกใช้วิดเจ็ตสร้างปุ่มกดเลือก 1 อัน
                info: entry.value, // ส่งข้อมูลวัสดุ
                isSelected:
                    entry.key ==
                    selectedLabel, // เช็คว่าใช่วัสดุที่เลือกอยู่ไหม (เพื่อทำปุ่มวิทยุ)
                isAiGuess:
                    entry.key ==
                    aiLabel, // เช็คว่าใช่วัสดุที่ AI ทายไหม (เพื่อติดป้ายแนะนำ)
                onTap: () => Navigator.pop(
                  context,
                  entry.key,
                ), // พอกดปุ๊บ ให้ปิดแผ่นสไลด์ พร้อมส่งชื่อวัสดุที่เลือกกลับไป
              ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 7: ข้อความแจ้งเตือนสีแดง (เช่น ความมั่นใจต่ำ)
// ===========================================================================
class ResultWarningText extends StatelessWidget {
  const ResultWarningText(this.message, {super.key}); // รับข้อความมา
  final String message; // ตัวแปรเก็บข้อความ

  @override
  Widget build(BuildContext context) {
    return Text(
      message, // โชว์ข้อความ
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(
          context,
        ).colorScheme.error, // กำหนดสีเป็นสีแดง Error ดึงจากธีม
        fontWeight: FontWeight.w600, // ตัวหนาปานกลาง
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 8: ข้อความตัวเล็กสีเทาๆ (เอาไว้โชว์บอกสูตรคำนวณ)
// ===========================================================================
class ResultFormulaHint extends StatelessWidget {
  const ResultFormulaHint(this.formula, {super.key}); // รับข้อความสูตรมา
  final String formula; // ตัวแปรเก็บสูตร

  @override
  Widget build(BuildContext context) {
    return Text(
      formula, // โชว์สูตร
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant, // ให้สีเป็นสีเทาอ่อนๆ ไม่แย่งความเด่น
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 9: ปุ่มหลัก (ปุ่มสีทึบ เช่น ปุ่มบันทึกข้อมูล, ปุ่มถัดไป)
// ===========================================================================
class PrimaryActionButton extends StatelessWidget {
  // คอนสตรัคเตอร์ของปุ่มหลัก (รับข้อความ, ฟังก์ชันตอนกด, และไอคอนเสริม)
  const PrimaryActionButton({
    required this.label, // รับข้อความบนปุ่ม (บังคับใส่)
    required this.onPressed, // รับฟังก์ชันที่จะให้ทำงานเมื่อปุ่มถูกกด (บังคับใส่)
    this.icon, // รับไอคอน (ใส่หรือไม่ใส่ก็ได้ ถ้าไม่ใส่จะเป็นค่า null)
    super.key,
  });

  final String label; // ตัวแปรเก็บข้อความบนปุ่ม
  final VoidCallback? onPressed; // ตัวแปรเก็บฟังก์ชันเมื่อโดนกด
  final IconData? icon; // ตัวแปรเก็บไอคอน

  @override
  Widget build(BuildContext context) {
    // ฟังก์ชันวาดหน้าตาปุ่ม
    // กำหนดสไตล์การตกแต่งปุ่ม (FilledButton)
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(
        ResultStyle.actionButtonHeight,
      ), // 📌 ดึงความสูงปุ่มมาจาก ResultStyle
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResultStyle.actionButtonRadius,
        ), // 📌 ดึงความโค้งมนของปุ่มมาจาก ResultStyle
      ),
      // 💡 กำหนดสไตล์ตัวหนังสือในปุ่ม โดยดึงขนาดฟอนต์จาก ResultStyle.actionButtonFontSize มาใช้งาน
      textStyle: const TextStyle(
        fontSize: ResultStyle.actionButtonFontSize, // ขนาดตัวหนังสือ
        fontWeight: FontWeight.bold, // ตัวหนังสือหนา
      ),
    );

    // เช็คเงื่อนไข: ถ้าไม่ได้ส่งไอคอนมา (icon เป็น null)
    if (icon == null) {
      return FilledButton(
        onPressed: onPressed, // ใส่ฟังก์ชันเมื่อโดนกด
        style: style, // ใส่สไตล์การแต่งปุ่ม
        child: Text(label), // วาดข้อความบนปุ่ม
      );
    }

    // แต่ถ้ามีไอคอนถูกส่งมาด้วย ให้สร้างปุ่มแบบมีไอคอนคู่กับข้อความ
    return FilledButton.icon(
      onPressed: onPressed, // ใส่ฟังก์ชันเมื่อโดนกด
      style: style, // ใส่สไตล์การแต่งปุ่ม
      icon: Icon(icon), // วาดไอคอน
      label: Text(label), // วาดข้อความ
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 10: ปุ่มรอง (ปุ่มแบบมีแค่เส้นขอบ เช่น ปุ่มย้อนกลับ)
// ===========================================================================
class SecondaryActionButton extends StatelessWidget {
  // คอนสตรัคเตอร์ของปุ่มรอง (รับข้อความ และฟังก์ชันตอนกด)
  const SecondaryActionButton({
    required this.label, // รับข้อความบนปุ่ม
    required this.onPressed, // รับฟังก์ชันตอนกด
    super.key,
  });

  final String label; // ตัวแปรเก็บข้อความ
  final VoidCallback? onPressed; // ตัวแปรเก็บฟังก์ชัน

  @override
  Widget build(BuildContext context) {
    // ฟังก์ชันวาดปุ่ม
    return OutlinedButton(
      // สร้างปุ่มแบบมีแค่เส้นขอบรอบนอก (โปร่งใส)
      onPressed: onPressed, // ใส่ฟังก์ชันเมื่อโดนกด
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(
          ResultStyle.actionButtonHeight,
        ), // 📌 ดึงความสูงให้เท่ากับปุ่มหลักเป๊ะๆ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResultStyle.actionButtonRadius,
          ), // 📌 ดึงความโค้งมนให้เท่าปุ่มหลัก
        ),
        // 💡 กำหนดขนาดตัวหนังสือให้ใหญ่เท่ากัน โดยดึงมาจาก ResultStyle.actionButtonFontSize
        textStyle: const TextStyle(
          fontSize: ResultStyle.actionButtonFontSize, // ขนาดฟอนต์
          fontWeight: FontWeight.bold, // ตัวหนังสือหนา
        ),
      ),
      child: Text(label), // วาดข้อความข้างในปุ่ม
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 11: รายการวัสดุ 1 บรรทัด (อยู่ในหน้าต่างสไลด์ MaterialPickerSheet)
// ===========================================================================
class _MaterialOptionTile extends StatelessWidget {
  const _MaterialOptionTile({
    required this.info, // ข้อมูลวัสดุ
    required this.isSelected, // เป็นตัวที่ถูกเลือกอยู่ไหม (true/false)
    required this.isAiGuess, // เป็นตัวที่ AI ทายไว้ไหม (true/false)
    required this.onTap, // ฟังก์ชันตอนโดนกด
  });

  final MaterialInfo info;
  final bool isSelected;
  final bool isAiGuess;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      // สร้างลิสต์รายการ 1 บรรทัดที่กดได้
      contentPadding: EdgeInsets.zero, // ลบขอบด้านใน
      onTap: onTap, // คำสั่งตอนกด
      leading: Icon(
        // ไอคอนด้านหน้า (ปุ่มวิทยุ)
        isSelected
            ? Icons.radio_button_checked_rounded
            : Icons
                  .radio_button_off_rounded, // ถ้าถูกเลือกให้เป็นกลมๆ มีจุดตรงกลาง
        color: isSelected
            ? colorScheme.primary
            : colorScheme.outline, // ถ้าถูกเลือกเป็นสีหลัก ถ้าไม่ให้เป็นสีเทา
      ),
      title: Text(
        // หัวข้อรายการ
        info.displayName, // ชื่อวัสดุ
        style: TextStyle(
          fontWeight: isSelected
              ? FontWeight.w800
              : FontWeight.w500, // ถ้าถูกเลือกให้ตัวหนา
        ),
      ),
      subtitle: Text(info.category), // คำอธิบายย่อย เป็นหมวดหมู่ขยะ
      trailing:
          isAiGuess // ไอคอน/ป้ายด้านหลัง ถ้า AI ทายไว้ให้สร้างป้าย
          ? Chip(
              // ป้ายกำกับ (Chip)
              label: const Text('ผลการวิเคราะห์'), // ข้อความในป้าย
              visualDensity: VisualDensity.compact, // ย่อขนาดป้ายให้เล็ก
              backgroundColor: colorScheme.primaryContainer, // สีพื้นหลังป้าย
              labelStyle: TextStyle(
                color: colorScheme.onPrimaryContainer,
              ), // สีข้อความในป้าย
              side: BorderSide.none, // ลบเส้นขอบป้ายทิ้ง
            )
          : null, // ถ้า AI ไม่ได้ทาย ไม่ต้องสร้างอะไรเลย
    );
  }
}
