// ===== ส่วน Import: ดึงเครื่องมือที่ไฟล์นี้ต้องใช้ =====

// นำเข้า dart:io เพื่อใช้คลาส File อ่านไฟล์รูปในเครื่อง (ใช้ได้บนมือถือ/เดสก์ท็อป ไม่รองรับ Web)
import 'dart:io';

// นำเข้าชุด Widget พื้นฐานของ Flutter (Scaffold, AppBar, Text, ListView ฯลฯ)
import 'package:flutter/material.dart';

// นำเข้าค่าสีกลางของแอป (ทำให้เปลี่ยนธีมได้จากที่เดียว)
// ../../../../ คือถอยขึ้นไป 4 ชั้นเพื่อไปที่โฟลเดอร์ core
import '../../../../core/constants/app_colors.dart';

// นำเข้าตัวช่วยจัดรูปแบบวันที่/เวลา (ไฟล์นี้ไม่ได้ส่งมา: สมมติว่าคืนค่าเป็น String)
import '../../../../core/utils/date_formatter.dart';

// นำเข้าตัวช่วยจัดรูปแบบตัวเลข เช่น เงิน และ CO₂ (ไม่ได้ส่งมา: สมมติว่าคืนค่าเป็น String)
import '../../../../core/utils/number_formatter.dart';

// นำเข้า Model ที่เก็บข้อมูลประวัติ 1 รายการ (ไม่ได้ส่งมา)
// ../../ คือถอย 2 ชั้นไปที่โฟลเดอร์ของ feature แล้วเข้า data/models
import '../../data/models/history_record_model.dart';


// ===== คลาสหน้าจอหลัก =====

// StatelessWidget = Widget ที่ "ไม่มีสถานะเปลี่ยนแปลง" หน้านี้แค่แสดงข้อมูลที่ได้รับมา จึงไม่ต้องใช้ State
class HistoryDetailScreen extends StatelessWidget {
  // const constructor: ทำให้ Flutter สร้าง Widget นี้แบบคงที่ได้ ประหยัดหน่วยความจำ
  // super.key ส่งค่า key ต่อไปให้คลาสแม่
  // required this.record = ต้องส่ง record มาเสมอ ไม่ส่งจะ Error ตอน compile (Null Safety)
  const HistoryDetailScreen({super.key, required this.record});

  // เก็บข้อมูลประวัติที่รับมา (final = กำหนดค่าได้ครั้งเดียว เปลี่ยนทีหลังไม่ได้)
  final HistoryRecordModel record;

  // @override = เรากำลังเขียนทับเมธอด build ของ StatelessWidget
  @override
  Widget build(BuildContext context) {
    // สร้างอ็อบเจ็กต์ File จากตำแหน่งไฟล์รูปที่บันทึกไว้ (ยังไม่ได้อ่านไฟล์จริง เป็นแค่ "ตัวชี้")
    final imageFile = File(record.imagePath);

    // ตรวจว่าไฟล์รูปมีอยู่จริงไหม (existsSync = เช็คแบบรอผลทันที ได้ true/false)
    // ถ้าไม่มี (ถูกลบ/ไม่เคยมีรูป) จะไปแสดงไอคอนสำรองแทน
    final hasImage = imageFile.existsSync();

    // Scaffold = โครงหน้าจอมาตรฐานของ Material (มี appBar, body ฯลฯ)
    return Scaffold(
      // สีพื้นหลังทั้งหน้า ดึงจากค่าสีกลาง
      backgroundColor: AppColors.background,

      // แถบด้านบนของหน้าจอ
      appBar: AppBar(
        // ชื่อหน้า (const เพราะเป็นข้อความตายตัว ไม่เปลี่ยนตามข้อมูล)
        title: const Text('รายละเอียดประวัติ'),
        // ให้สีแถบบนตรงกับพื้นหลังหน้า ดูเป็นผืนเดียวกัน
        backgroundColor: AppColors.background,
      ),

      // ส่วนเนื้อหาหลักของหน้า
      body: SafeArea(
        // SafeArea = เว้นพื้นที่ไม่ให้เนื้อหาไปทับรอยบาก/แถบสถานะ/ปุ่มระบบ
        // ListView = รายการที่เลื่อนขึ้นลงได้ กันเนื้อหาล้นจอบนมือถือจอเล็ก
        child: ListView(
          // เว้นขอบรอบ ๆ ทั้งหน้า 20 พิกเซล
          padding: const EdgeInsets.all(20),
          // รายการ Widget ที่เรียงลงมาเป็นแนวตั้ง
          children: [
            // ----- ส่วนที่ 1: รูปภาพ (หรือไอคอนสำรอง) -----

            // ClipRRect = ตัดมุมของลูกให้โค้งมน (ทำให้รูปมีมุมมน)
            ClipRRect(
              // รัศมีมุมโค้ง 28 พิกเซล
              borderRadius: BorderRadius.circular(28),
              // Ternary operator: ถ้ามีรูป -> แสดงรูป  ถ้าไม่มี -> แสดงกล่องสีพร้อมไอคอน
              child: hasImage
                  // กรณีมีรูป: แสดงรูปจากไฟล์ในเครื่อง
                  ? Image.file(
                      // ไฟล์ที่จะแสดง
                      imageFile,
                      // กำหนดความสูงรูปคงที่ 260
                      height: 260,
                      // กว้างเต็มพื้นที่ที่มี
                      width: double.infinity,
                      // BoxFit.cover = ขยายรูปให้เต็มกรอบ ส่วนเกินถูกตัดทิ้ง ไม่บิดสัดส่วน
                      fit: BoxFit.cover,
                    )
                  // กรณีไม่มีรูป: แสดงกล่องสีเขียวอ่อนแทน
                  : Container(
                      // ความสูงเท่ากับรูปจริง เพื่อให้ layout ไม่กระโดด
                      height: 260,
                      // กว้างเต็มพื้นที่
                      width: double.infinity,
                      // สีพื้นกล่อง
                      color: AppColors.cardGreen,
                      // ไอคอนรูปภาพตรงกลางกล่อง (const เพราะค่าไม่เปลี่ยน)
                      child: const Icon(
                        // ไอคอนรูปภาพแบบเส้นขอบ
                        Icons.image_outlined,
                        // ขนาดไอคอน 72
                        size: 72,
                        // สีไอคอนเขียวเข้ม
                        color: AppColors.darkGreen,
                      ),
                    ),
            ),

            // เว้นระยะแนวตั้ง 20 ระหว่างรูปกับการ์ดแรก
            const SizedBox(height: 20),

            // ----- ส่วนที่ 2: การ์ดผลการวิเคราะห์ -----
            _SectionCard(
              // หัวข้อของการ์ด
              title: 'ผลการวิเคราะห์',
              // แถวข้อมูลภายในการ์ด
              children: [
                // แถวชื่อวัสดุที่ AI ทำนาย
                _DetailRow(label: 'วัสดุ', value: record.material),
                // แถวหมวดหมู่ของวัสดุ
                _DetailRow(label: 'หมวดหมู่', value: record.category),
                // แถวความมั่นใจของโมเดล
                _DetailRow(
                  label: 'ความมั่นใจ',
                  // ปัดเลขทศนิยม 1 ตำแหน่ง แล้วต่อด้วยเครื่องหมาย % (ค่า confidence ต้องเป็นสเกล 0-100)
                  // ${...} = แทรกค่าตัวแปรลงในข้อความ (String Interpolation)
                  value: '${record.confidence.toStringAsFixed(1)}%',
                ),
              ],
            ),

            // เว้นระยะ 14 ระหว่างการ์ด
            const SizedBox(height: 14),

            // ----- ส่วนที่ 3: การ์ดประเมินราคา -----
            _SectionCard(
              title: 'ประเมินราคา',
              children: [
                // แถวน้ำหนัก
                _DetailRow(
                  label: 'น้ำหนัก',
                  // ปัดทศนิยม 2 ตำแหน่ง แล้วต่อหน่วย กก.
                  value: '${record.weight.toStringAsFixed(2)} กก.',
                ),
                // แถวราคาต่อกิโลกรัม
                _DetailRow(
                  label: 'ราคา/กก.',
                  // ใช้ตัวช่วยจัดรูปแบบเป็นข้อความเงิน (เช่น มีเครื่องหมายคั่นหลักพัน)
                  value: NumberFormatter.money(record.pricePerKg),
                ),
                // แถวราคาประเมินรวม (น้ำหนัก x ราคา/กก.)
                _DetailRow(
                  label: 'ราคาประเมิน',
                  value: NumberFormatter.money(record.estimatedPrice),
                  // เปิดโหมดเน้น -> ตัวอักษรเป็นสีเขียวเข้ม เพราะเป็นตัวเลขสำคัญที่สุด
                  isHighlight: true,
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ----- ส่วนที่ 4: การ์ดผลกระทบต่อสิ่งแวดล้อม -----
            _SectionCard(
              title: 'ผลกระทบต่อสิ่งแวดล้อม',
              children: [
                // แถว CO₂ ที่ลดได้
                _DetailRow(
                  label: 'CO₂ ที่ลดได้',
                  // จัดรูปแบบค่า CO₂ ผ่านตัวช่วยกลาง
                  value: NumberFormatter.co2(record.co2Saved),
                ),
                // แถวคะแนนสะสมที่ได้จากรายการนี้
                _DetailRow(
                  label: 'คะแนนที่ได้รับ',
                  // แทรกจำนวนคะแนนลงในข้อความ
                  value: '${record.pointsEarned} คะแนน',
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ----- ส่วนที่ 5: การ์ดข้อมูลเพิ่มเติม -----
            _SectionCard(
              title: 'ข้อมูลเพิ่มเติม',
              children: [
                // แถวหมายเหตุ: ส่งผ่าน _safeNote เพื่อกันกรณี null/ว่าง ให้แสดงเป็น '-'
                _DetailRow(label: 'หมายเหตุ', value: _safeNote(record.note)),
                // แถวเวลาที่สร้างรายการ
                _DetailRow(
                  label: 'สร้างเมื่อ',
                  // แปลงวันที่-เวลาเป็นข้อความรูปแบบ วัน/เดือน/ปี เวลา (ตามที่ DateFormatter กำหนด)
                  value: DateFormatter.slashDateTime(record.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันช่วยจัดการหมายเหตุ
  // static = เรียกใช้ได้โดยไม่ต้องมีอ็อบเจ็กต์ (ไม่ต้องพึ่งตัวแปรของคลาส)
  // String? = รับค่าเป็น String หรือ null ก็ได้ (Null Safety) คืนค่าเป็น String ที่ไม่ใช่ null เสมอ
  static String _safeNote(String? note) {
    // ถ้าเป็น null หรือเป็นข้อความว่าง/มีแต่ช่องว่าง (trim ตัดช่องว่างหัวท้ายก่อนเช็ค)
    // เงื่อนไข note == null ต้องมาก่อน เพราะถ้า null แล้วเรียก note.trim() จะ Error
    if (note == null || note.trim().isEmpty) {
      // แสดงขีด '-' แทนเพื่อไม่ให้ช่องว่างดูเหมือนบั๊ก
      return '-';
    }

    // กรณีมีข้อความจริง: คืนข้อความที่ตัดช่องว่างหัวท้ายแล้ว
    // (Dart รู้แล้วว่า note ไม่ใช่ null ตรงนี้ เพราะผ่านเงื่อนไขด้านบนมาแล้ว)
    return note.trim();
  }
}


// ===== Widget ย่อยที่ 1: การ์ดหัวข้อ =====

// ขึ้นต้นด้วย _ = private ใช้ได้เฉพาะในไฟล์นี้ (Encapsulation)
class _SectionCard extends StatelessWidget {
  // รับหัวข้อและรายการแถวที่จะแสดงในการ์ด (ทั้งสองค่าบังคับต้องส่ง)
  const _SectionCard({required this.title, required this.children});

  // ข้อความหัวข้อของการ์ด
  final String title;
  // รายการ Widget ที่จะวางต่อจากหัวข้อ (ส่วนใหญ่คือ _DetailRow)
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Container = กล่องที่ตกแต่งได้ (ระยะขอบ สี มุมโค้ง เส้นขอบ)
    return Container(
      // เว้นระยะภายในกล่อง 18 พิกเซลรอบด้าน
      padding: const EdgeInsets.all(18),
      // ตกแต่งกล่อง
      decoration: BoxDecoration(
        // สีพื้นการ์ด
        color: AppColors.cardGreen,
        // มุมโค้งมน 26
        borderRadius: BorderRadius.circular(26),
        // เส้นขอบรอบการ์ด
        border: Border.all(color: AppColors.cardBorder),
      ),
      // Column = เรียงลูกในแนวตั้ง
      child: Column(
        // จัดลูกให้ชิดซ้ายในแนวขวาง (หัวข้อจะได้อยู่ซ้าย)
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ข้อความหัวข้อการ์ด
          Text(
            title,
            // ดึงสไตล์ titleMedium จากธีมของแอป แล้วปรับแต่งต่อด้วย copyWith
            // ?. = ถ้า titleMedium เป็น null ให้ข้ามไป ไม่ Error (Null Safety)
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              // ตัวหนามาก
              fontWeight: FontWeight.w900,
              // สีตัวอักษรเข้ม
              color: AppColors.textDark,
            ),
          ),
          // เว้นระยะระหว่างหัวข้อกับแถวข้อมูล
          const SizedBox(height: 12),
          // ... (Spread Operator) = กระจายสมาชิกใน children ออกมาเป็นลูกของ Column ทีละตัว
          ...children,
        ],
      ),
    );
  }
}


// ===== Widget ย่อยที่ 2: แถวข้อมูล "ป้ายชื่อ : ค่า" =====

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    // ป้ายชื่อบังคับต้องส่ง
    required this.label,
    // ค่าบังคับต้องส่ง
    required this.value,
    // ไม่บังคับ: ถ้าไม่ส่งมาจะเป็น false (ไม่เน้นสี)
    this.isHighlight = false,
  });

  // ข้อความฝั่งซ้าย (ชื่อหัวข้อย่อย)
  final String label;
  // ข้อความฝั่งขวา (ค่าที่จะแสดง)
  final String value;
  // true = แสดงค่าเป็นสีเขียวเข้มเพื่อเน้น
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    // เลือกสีของค่า: ถ้าเน้น -> เขียวเข้ม  ถ้าไม่ -> สีตัวอักษรปกติ
    // หมายเหตุ: 0xFF1F7A35 ฮาร์ดโค้ดไว้ตรงนี้ ไม่ได้มาจาก AppColors
    final valueColor = isHighlight
        ? const Color(0xFF1F7A35)
        : AppColors.textDark;

    // Padding = เว้นระยะล่างของแต่ละแถว 10 เพื่อไม่ให้แถวชิดกัน
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      // Row = เรียงลูกในแนวนอน (ซ้าย: ป้ายชื่อ / ขวา: ค่า)
      child: Row(
        // จัดลูกให้ชิดบนกรณีข้อความยาวหลายบรรทัด
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded = ให้ลูกยืดกินพื้นที่ที่เหลือ (ตัวนี้ได้ครึ่งหนึ่ง)
          Expanded(
            child: Text(
              // ป้ายชื่อ
              label,
              // ใช้สไตล์ bodyMedium ของธีม แล้วปรับสีเป็นสีรอง (จางกว่า) และตัวหนาปานกลาง
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // ช่องว่างแนวนอน 12 กั้นระหว่างป้ายชื่อกับค่า
          const SizedBox(width: 12),
          // Expanded ตัวที่สอง: ได้พื้นที่อีกครึ่ง (ค่าจึงไม่ล้นออกนอกจอ และขึ้นบรรทัดใหม่เองถ้ายาว)
          Expanded(
            child: Text(
              // ค่าที่จะแสดง
              value,
              // จัดชิดขวา
              textAlign: TextAlign.right,
              // ใช้สไตล์ bodyMedium ของธีม แต่ใช้สีที่คำนวณไว้ด้านบนและตัวหนามาก
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}