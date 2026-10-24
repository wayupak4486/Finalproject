import 'dart:io'; // นำเข้าเครื่องมือจัดการไฟล์ (เอาไว้เช็คว่ารูปภาพมีอยู่จริงไหมในเครื่องมือถือ)

import 'package:flutter/material.dart'; // นำเข้าชุดเครื่องมือสร้างหน้าจอ UI ของ Flutter

import '../../../../core/constants/app_colors.dart'; // นำเข้าไฟล์สีประจำแอป (เช่น สีเขียว สีแดง)
import '../../../../core/utils/date_formatter.dart'; // นำเข้าตัวช่วยจัดรูปแบบวันที่และเวลาให้อ่านง่าย
import '../../../../core/utils/number_formatter.dart'; // นำเข้าตัวช่วยจัดรูปแบบตัวเลขเงินและคาร์บอน (เช่น ใส่ลูกน้ำ)
import '../../data/models/history_record_model.dart'; // นำเข้าโครงสร้างข้อมูลประวัติ (Model)

// ===========================================================================
// การ์ดแสดงผลประวัติแต่ละรายการในหน้าประวัติ (HistoryRecordCard)
// ===========================================================================
class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard({
    required this.record, // รับข้อมูลประวัติ 1 รายการ
    required this.onTap, // ฟังก์ชันเมื่อกดที่การ์ด (เปิดดูหน้ารายละเอียด)
    required this.onDelete, // ฟังก์ชันเมื่อกดปุ่มถังขยะ (ลบรายการนี้)
    required this.onWeightConfirmed, // ฟังก์ชันยืนยันน้ำหนัก (กรณีรายการค้างการกรอกน้ำหนัก)
    super.key,
  });

  final HistoryRecordModel record; // ตัวแปรเก็บข้อมูลประวัติ
  final VoidCallback onTap; // ตัวแปรเก็บคำสั่งตอนกดการ์ด
  final VoidCallback onDelete; // ตัวแปรเก็บคำสั่งตอนกดลบ
  final ValueChanged<double>
  onWeightConfirmed; // ตัวแปรเก็บคำสั่งตอนยืนยันน้ำหนักฟฟฟ

  // กำหนดความโค้งมนของขอบการ์ด (กำหนดไว้ตัวเดียวเพื่อให้ทุกส่วนโค้งเท่ากันสวยงาม)
  static const double _cardRadius = 28;

  @override
  Widget build(BuildContext context) {
    // เช็คว่ารายการนี้ "ยังค้างการกรอกน้ำหนักอยู่หรือไม่?" (ดูจาก isPendingWeight ใน Model)
    final isPending = record.isPendingWeight;

    return InkWell(
      borderRadius: BorderRadius.circular(
        _cardRadius,
      ), // ทำให้เวลาเอานิ้วกดมีการแสดงผลเอฟเฟกต์โค้งมน
      onTap: onTap, // พอกดที่การ์ด ให้เรียกฟังก์ชันเปิดหน้าจอรายละเอียด
      child: Container(
        padding: const EdgeInsets.all(
          14,
        ), // เว้นระยะห่างขอบด้านในของการ์ด 14 พิกเซล
        decoration: BoxDecoration(
          // 🎨 ถ้ายังค้างน้ำหนัก ให้พื้นหลังการ์ดเป็นสีแดงอ่อน (AppColors.cardPendingRed) เพื่อเตือนสายตา
          // แต่ถ้ากรอกน้ำหนักครบแล้ว ให้ใช้สีเขียวปกติ (AppColors.cardGreen)
          color: isPending ? AppColors.cardPendingRed : AppColors.cardGreen,
          borderRadius: BorderRadius.circular(
            _cardRadius,
          ), // ความโค้งมนขอบการ์ด
          border: Border.all(
            color: AppColors.cardBorder,
          ), // วาดเส้นขอบการ์ดสีเทาอ่อน
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(), // 📌 เรียกฟังก์ชันวาดรูปภาพตัวอย่าง (หรือไอคอนเลือกเอง) ด้านซ้ายของการ์ด
                const SizedBox(width: 14), // เว้นระยะห่าง 14 พิกเซล
                Expanded(
                  child: _buildDetails(context, isPending: isPending),
                ), // ส่วนแสดงข้อความรายละเอียดทางขวา
                IconButton(
                  tooltip: 'ลบ',
                  onPressed: onDelete, // พอกดไอคอนถังขยะ ให้เรียกฟังก์ชันลบ
                  icon: const Icon(Icons.delete_outline_rounded), // ไอคอนถังขยะ
                  color: Colors.redAccent, // สีแดง
                ),
              ],
            ),
            // ถ้าสถานะยังค้างน้ำหนัก (isPending เป็น true) ให้แสดงช่องพิมพ์กรอกน้ำหนักแบบด่วนทันทีในการ์ดนี้
            if (isPending) ...[
              const SizedBox(height: 12),
              _PendingWeightInput(onConfirmed: onWeightConfirmed),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 📌 ฟังก์ชันวาดรูปภาพตัวอย่างด้านซ้ายของการ์ดประวัติ (รองรับทั้งรูปถ่ายและเลือกเอง)
  // ===========================================================================
  Widget _buildThumbnail() {
    // 💡 เช็คพิเศษ: ถ้า record.imagePath เป็น null หรือเป็นค่าว่าง แสดงว่ารายการนี้ผู้ใช้
    // "เลือกประเภทวัสดุด้วยตนเอง" โดยไม่ได้ถ่ายรูปมาตั้งแต่แรก
    if (record.imagePath == null || record.imagePath!.isEmpty) {
      return Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          color: Colors
              .green
              .shade100, // เทสีพื้นหลังเป็นสีเขียวพาสเทลอ่อนๆ สบายตา
          borderRadius: BorderRadius.circular(20), // มุมโค้งมนของกล่อง
          border: Border.all(
            color: Colors.green.shade300,
            width: 1,
          ), // วาดเส้นขอบสีเขียวอ่อน
        ),
        child: const Center(
          child: Icon(
            Icons
                .list_alt_rounded, // 📌 ใช้ไอคอนรูปรายการลิสต์ (List) แทนรูปถ่ายจริง
            size: 38,
            color: Color(0xFF1F7A35), // ใช้สีเขียวเข้มเข้ากับธีมแอป
          ),
        ),
      );
    }

    // กรณีปกติ: ถ้ารายการนี้มีภาพถ่ายจากการสแกนจริง ให้เช็คว่าไฟล์ภาพมีอยู่จริงในเครื่องไหม
    final imageFile = File(record.imagePath);
    final hasImage = imageFile.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20), // ตัดขอบรูปภาพให้โค้งมน 20
      child: hasImage
          ? Image.file(
              imageFile,
              width: 92,
              height: 92,
              fit: BoxFit.cover,
            ) // ถ้าไฟล์มีอยู่จริง โชว์รูปถ่ายจริง
          : Container(
              width: 92,
              height: 92,
              color: Colors.white,
              child: const Icon(
                Icons.image_outlined,
                size: 34,
              ), // ถ้าหาไฟล์ไม่เจอ ให้โชว์ไอคอนรูปภาพสำรอง
            ),
    );
  }

  // ฟังก์ชันวาดรายละเอียดข้อความทางขวาของการ์ด (ชื่อวัสดุ, หมวดหมู่, น้ำหนัก, ราคา, CO2, วันที่)
  Widget _buildDetails(BuildContext context, {required bool isPending}) {
    final textTheme = Theme.of(context).textTheme;
    // เช็คว่ามีหมายเหตุบันทึกไว้ไหม
    final hasNote = record.note != null && record.note!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.material, // โชว์ชื่อวัสดุ
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          record.category, // โชว์หมวดหมู่ขยะ
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // ถ้ายังค้างน้ำหนัก ให้ซ่อนบรรทัดน้ำหนักไปก่อน (เพราะยังไม่ได้กรอก จะได้ไม่โชว์เลข 0.00 กก. ให้สับสน)
        if (!isPending) ...[
          HistoryMiniInfoRow(
            icon: Icons.scale_rounded,
            text: '${record.weight.toStringAsFixed(2)} กก.',
          ),
          const SizedBox(height: 4),
        ],
        HistoryMiniInfoRow(
          icon: Icons.payments_rounded,
          text: NumberFormatter.money(record.estimatedPrice), // โชว์ราคาประเมิน
        ),
        const SizedBox(height: 4),
        HistoryMiniInfoRow(
          icon: Icons.eco_rounded,
          text:
              '${NumberFormatter.co2(record.co2Saved)} • ${record.pointsEarned} คะแนน', // โชว์ CO2 และ คะแนน
        ),
        if (hasNote) ...[
          const SizedBox(height: 6),
          Text(
            record.note!.trim(), // โชว์หมายเหตุ (ถ้ามี)
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textMutedSecondary,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text(
          DateFormatter.slashDateTime(
            record.createdAt,
          ), // โชว์วันที่และเวลาที่บันทึก
          style: textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7468)),
        ),
      ],
    );
  }
}

// ===========================================================================
// ช่องกรอกน้ำหนักแบบด่วน (โชว์เฉพาะตอนที่การ์ดยังค้างสถานะรอใส่น้ำหนัก)
// ===========================================================================
class _PendingWeightInput extends StatefulWidget {
  const _PendingWeightInput({required this.onConfirmed});

  final ValueChanged<double> onConfirmed;

  @override
  State<_PendingWeightInput> createState() => _PendingWeightInputState();
}

class _PendingWeightInputState extends State<_PendingWeightInput> {
  final TextEditingController _controller =
      TextEditingController(); // ตัวดูดข้อความจากช่องพิมพ์น้ำหนัก

  @override
  void dispose() {
    _controller.dispose(); // คืนหน่วยความจำ RAM ตอนปิดวิดเจ็ตนี้
    super.dispose();
  }

  // ฟังก์ชันเมื่อกดปุ่มยืนยันน้ำหนัก
  void _submit() {
    final weight = double.tryParse(
      _controller.text,
    ); // แปลงตัวอักษรที่พิมพ์เป็นตัวเลข
    if (weight == null || weight <= 0)
      return; // ถ้าพิมพ์ไม่เป็นตัวเลข หรือค่าน้อยกว่าหรือเท่ากับ 0 ให้หยุด

    widget.onConfirmed(weight); // ส่งค่าน้ำหนักที่กรอกกลับไปทำงานต่อ
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.scale_rounded,
          size: 18,
          color: AppColors.darkGreen,
        ), // ไอคอนตราชั่ง
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller, // เชื่อมตัวดูดข้อความ
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ), // บังคับแป้นพิมพ์ตัวเลข
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              isDense: true,
              hintText: 'กรอกน้ำหนัก (กก.)',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 10,
              ),
            ),
            onSubmitted: (_) =>
                _submit(), // พอกดปุ่ม Enter ที่คีย์บอร์ด ให้บันทึกทันที
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'ยืนยันน้ำหนัก',
          onPressed: _submit, // พอกดปุ่มติ๊กถูก ให้บันทึก
          icon: const Icon(Icons.check_circle_rounded),
          color: AppColors.primaryGreen,
        ),
      ],
    );
  }
}

// ===========================================================================
// ชิ้นส่วนแถวข้อมูลย่อย (ใช้แสดงไอคอนคู่กับข้อความเล็กๆ ในการ์ดประวัติ)
// ===========================================================================
class HistoryMiniInfoRow extends StatelessWidget {
  const HistoryMiniInfoRow({required this.icon, required this.text, super.key});

  final IconData icon; // ไอคอน
  final String text; // ข้อความ

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.darkGreen), // วาดไอคอน
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text, // วาดข้อความ
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// หน้าจอแสดงผลเวลาที่ "ยังไม่มีประวัติในระบบ" (หน้าจอว่างเปล่า)
// ===========================================================================
class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.history_rounded, // ไอคอนนาฬิกาประวัติ
              size: 42,
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ยังไม่มีประวัติ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'สแกนและบันทึกวัสดุรีไซเคิลเพื่อดูที่นี่',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
