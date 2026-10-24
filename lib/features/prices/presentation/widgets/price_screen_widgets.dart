// ดึงเครื่องมือสร้างหน้าจอ UI จาก Flutter Framework
import 'package:flutter/material.dart';

// โซน Import ไฟล์อื่นๆ ที่เกี่ยวข้องในโปรเจกต์
import '../../../../core/constants/app_colors.dart'; // สีของแอป
import '../../../../core/utils/date_formatter.dart'; // ตัวแปลงรูปแบบวันที่และเวลา
import '../../../../core/utils/number_formatter.dart'; // ตัวแปลงรูปแบบตัวเลข (ใส่คอมม่า, จุดทศนิยม)
import '../../../../services/price_source/wongpanit_price_service.dart'; // ดึงชื่อแหล่งที่มาของราคา
import '../../data/models/material_price_model.dart'; // โครงสร้างข้อมูลราคารับซื้อ

// ===========================================================================
// คลาส PriceStyle: ทำหน้าที่เป็น Configuration สำหรับปรับขนาด UI (Design System)
// ===========================================================================
class PriceStyle {
  // Constructor แบบ Private (มีขีดล่าง) เพื่อป้องกันไม่ให้ใครสร้าง Object จากคลาสนี้ด้วยเผลอ
  // เพราะคลาสนี้มีแต่ตัวแปร static ที่เรียกใช้ผ่านชื่อคลาสได้เลย
  PriceStyle._();

  // static const = ตัวแปรที่ฝังอยู่ในคลาส แก้ไขไม่ได้ตอนรันแอป ประหยัดเมมโมรี่
  // double? = เก็บตัวเลขทศนิยม และเป็น null (ไม่มีค่า) ได้
  // ถ้าเป็น null ตัว Flutter จะไปดึงขนาดมาตรฐาน (Material 3 Theme) มาใช้แทน

  // ---------- ส่วนที่ 1: แถบชื่อหน้าจอ (AppBar) ----------
  static const double? appBarTitleFontSize =
      null; // ตัวหนังสือคำว่า "ราคารับซื้อ"

  // ---------- ส่วนที่ 2: กล่องคำอธิบายด้านบน ----------
  static const double? headerTitleFontSize =
      null; // หัวข้อ "ตารางราคารับซื้อวัสดุรีไซเคิล"
  static const double? headerSubtitleFontSize = null; // คำอธิบายยาวๆ

  // ---------- ส่วนที่ 3: แถวเวลาอัปเดต ----------
  static const double? lastUpdatedFontSize = null; // คำว่า "อัปเดตล่าสุด: ..."

  // ---------- ส่วนที่ 4: ปุ่มกดสีเขียว ----------
  static const double updateButtonHeight =
      58; // ความสูงปุ่ม (ปรับเลขนี้ให้ปุ่มอ้วนขึ้น/ผอมลง)
  static const double? updateButtonFontSize = 20; // ขนาดฟอนต์ในปุ่ม

  // ---------- ส่วนที่ 5: การ์ดแสดงราคาแต่ละรายการ ----------
  static const double cardIconSize = 28; // ขนาดของไอคอนรีไซเคิลด้านซ้าย
  static const double? cardTitleFontSize = 19; // ชื่อวัสดุ (เช่น พลาสติก PET)
  static const double? cardSubtitleFontSize = 15; // คำอธิบายใต้ชื่อ (หมวดหมู่)
  static const double? cardPriceFontSize =
      19; // ตัวเลขราคาด้านขวา (เช่น 3.80/กก.)
}

// ===========================================================================
// ชิ้นส่วนที่ 1: กล่องข้อความอธิบายด้านบนสุด (PriceHeaderCard)
// StatelessWidget = วิดเจ็ตแบบคงที่ ไม่มี State ของตัวเอง (ไม่มีตัวแปรที่เปลี่ยนแปลงจอได้)
// ===========================================================================
class PriceHeaderCard extends StatelessWidget {
  const PriceHeaderCard({super.key}); // รับค่า key ส่งให้คลาสแม่

  @override
  Widget build(BuildContext context) {
    // Container = กล่องอเนกประสงค์ ปรับขนาด สีพื้นหลัง เส้นขอบ ได้หมด
    return Container(
      width: double.infinity, // สั่งให้กว้างที่สุดเท่าที่หน้าจอจะกว้างได้
      padding: const EdgeInsets.all(
        20,
      ), // ดันเนื้อหาข้างในให้ห่างจากขอบกล่อง 20 พิกเซล (ทุกทิศ)
      decoration: BoxDecoration(
        // ตกแต่งหน้าตากล่อง
        color: AppColors.cardGreen, // สีพื้นหลังกล่อง (ดึงจากไฟล์สีของเรา)
        borderRadius: BorderRadius.circular(28), // ทำขอบให้โค้งมน 28 พิกเซล
        border: Border.all(color: AppColors.cardBorder), // ตีเส้นขอบรอบกล่อง
      ),
      // Column = เอาของมาเรียงต่อกันจาก "บนลงล่าง"
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // จัดให้ของทุกชิ้นใน Column ชิดซ้าย
        children: [
          // บรรทัดที่ 1
          Text(
            'ตารางราคารับซื้อวัสดุรีไซเคิล',
            // style: ดึง Theme ปัจจุบันมาใช้ แล้ว .copyWith (ก๊อปปี้แล้วทับ) ความหนา สี และขนาดใหม่
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900, // หนาสุด
              color: AppColors.textDark,
              fontSize: PriceStyle
                  .headerTitleFontSize, // 📌 ดึงขนาดจากคลาส PriceStyle
            ),
          ),
          const SizedBox(height: 8), // กล่องเปล่าสำหรับเว้นบรรทัด 8 พิกเซล
          // บรรทัดที่ 2
          Text(
            'แอปดึงรายการราคารับซื้อล่าสุดจากเว็บไซต์ร้านรับซื้อของเก่าวงษ์พาณิชย์ '
            'และบันทึกลง SQLite เพื่อใช้เป็นราคามาตรฐานทั่วทั้งแอป',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
              fontSize: PriceStyle.headerSubtitleFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 2: แถวบอกเวลา "อัปเดตล่าสุด" (PriceLastUpdatedRow)
// ===========================================================================
class PriceLastUpdatedRow extends StatelessWidget {
  // required = บังคับว่าตอนเรียกใช้ชิ้นส่วนนี้ "ต้อง" โยนค่า lastUpdated มาด้วย ห้ามลืม
  const PriceLastUpdatedRow({required this.lastUpdated, super.key});

  final DateTime? lastUpdated; // ตัวแปรเก็บเวลา (เป็น null ได้ถ้ายังไม่เคยโหลด)

  @override
  Widget build(BuildContext context) {
    // Row = เอาของมาเรียงต่อกันจาก "ซ้ายไปขวา"
    return Row(
      children: [
        const Icon(
          Icons.history_rounded, // ไอคอนรูปนาฬิกาย้อนหลัง
          color: AppColors.darkGreen,
          size: 22,
        ),
        const SizedBox(width: 8), // เว้นวรรคแนวนอน 8 พิกเซล
        // Expanded = สั่งให้ Text ขยายตัวกินพื้นที่แนวนอนที่เหลือทั้งหมด ป้องกันข้อความล้นจอ
        Expanded(
          child: Text(
            // 💡 Ternary Operator (? :) เช็คเงื่อนไข
            // ถ้า lastUpdated เป็น null ให้แสดงคำว่า 'ยังไม่มี...'
            // ถ้าไม่เป็น null (หลังเครื่องหมาย :) ให้เอาเวลาไปเข้าเครื่องจัดฟอร์แมต DateFormatter แล้วโชว์
            lastUpdated == null
                ? 'ยังไม่มีการอัปเดต'
                : 'อัปเดตล่าสุด: ${DateFormatter.dateTime(lastUpdated!)}', // lastUpdated! คือยืนยันว่ามันไม่ null แล้วนะ (เพราะเช็คดักไว้แล้ว)
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: PriceStyle.lastUpdatedFontSize,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 3: ปุ่มกดอัปเดตราคาจากเว็บ (PriceUpdateButton)
// ===========================================================================
class PriceUpdateButton extends StatelessWidget {
  const PriceUpdateButton({
    required this.isUpdating, // รับสถานะว่ากำลังหมุนอยู่ไหม (จากหน้า PriceScreen)
    required this.onPressed, // รับฟังก์ชันที่จะให้ทำตอนกดปุ่ม
    super.key,
  });

  final bool isUpdating;
  final VoidCallback
  onPressed; // VoidCallback = ชนิดข้อมูลของ "ฟังก์ชันที่ไม่มีการรับค่าและส่งค่า"

  @override
  Widget build(BuildContext context) {
    // FilledButton.icon = ปุ่มสีทึบที่มีไอคอนข้างใน (Material 3)
    return FilledButton.icon(
      // 💡 ถ้ากำลังอัปเดต (isUpdating เป็น true) จะเซ็ตให้เป็น null (ปุ่มจะกลายเป็นสีเทาและกดไม่ได้)
      // ถ้าไม่ได้อัปเดต จะใส่ฟังก์ชัน onPressed ให้กดได้ปกติ
      onPressed: isUpdating ? null : onPressed,

      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: Size.fromHeight(
          PriceStyle.updateButtonHeight,
        ), // 📌 บังคับความกว้างเต็มจอ (fromHeight) และกำหนดความสูงปุ่ม
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: PriceStyle.updateButtonFontSize,
        ),
      ),

      // 💡 การสลับหน้าตาไอคอนด้วย Ternary Operator
      icon: isUpdating
          ? const SizedBox(
              // ถ้ากำลังอัปเดต โชว์วงกลมหมุนๆ ขนาด 20x20
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4, // ความหนาของเส้นวงกลม
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.cloud_download_rounded,
              size: 28,
            ), // ถ้าไม่อัปเดต โชว์รูปเมฆดาวน์โหลด
      // 💡 การสลับข้อความ
      label: Text(isUpdating ? 'กำลังอัปเดต...' : 'อัปเดตราคาจากเว็บ'),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 4: แถบสีแดงแจ้งเตือนเวลา Error (PriceErrorBanner)
// ===========================================================================
class PriceErrorBanner extends StatelessWidget {
  const PriceErrorBanner({required this.message, super.key});
  final String message; // รับข้อความ Error (เช่น "ไม่มีอินเทอร์เน็ต")

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // ดึงสีแดงอ่อนสำหรับกล่อง Error จาก Theme หลักของ Material 3
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start, // จัดให้ไอคอนกับข้อความชิดขอบบน
        children: [
          Icon(
            Icons.error_outline_rounded,
            // ดึงสีแดงเข้มสำหรับเนื้อหาบนกล่อง Error
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            // บังคับข้อความให้ขึ้นบรรทัดใหม่ถ้ายาวเกินจอ ป้องกัน Error ขอบเหลือง
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 5: การ์ดแสดงราคาสินค้าแต่ละชิ้น (PriceCard)
// ===========================================================================
class PriceCard extends StatelessWidget {
  const PriceCard({required this.price, super.key});
  final MaterialPriceModel
  price; // รับข้อมูลราคามา 1 ก้อน (เช่น ข้อมูลของขวดพลาสติก)

  @override
  Widget build(BuildContext context) {
    // 💡 เช็คว่าราคามาจากแหล่ง 'วงษ์พาณิชย์' หรือไม่? (ถ้าใช่ isLive = true)
    final bool isLive = price.source == WongpanitPriceService.sourceName;

    return Container(
      padding: const EdgeInsets.all(16), // เว้นขอบด้านใน
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        // เรียงของ: ไอคอน -> ตรงกลาง(ข้อความ) -> ด้านขวา(ราคา)
        children: [
          // 1. กล่องรูปไอคอนด้านซ้าย
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.recycling_rounded,
              color: AppColors.primaryGreen,
              size: PriceStyle.cardIconSize,
            ),
          ),
          const SizedBox(width: 14),

          // 2. ข้อความตรงกลาง (หุ้ม Expanded เพื่อให้ดันตัวเลขราคาไปชิดขวาสุดจอ)
          Expanded(
            child: Column(
              // เรียง ชื่อวัสดุ ไว้บน หมวดหมู่
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.displayName, // แสดงชื่อวัสดุ (ตัวแปรจากโมเดล)
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    fontSize: PriceStyle.cardTitleFontSize,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  // 💡 String Interpolation: เอาตัวแปรมาผสมข้อความ
                  // ถ้า isLive จริง โชว์ "วงษ์พาณิชย์" ถ้าเท็จ โชว์ "ค่าเริ่มต้น"
                  '${price.category} • ${isLive ? 'วงษ์พาณิชย์' : 'ค่าเริ่มต้น'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: PriceStyle.cardSubtitleFontSize,
                  ),
                ),
              ],
            ),
          ),

          // 3. ข้อความด้านขวา (ราคา)
          Text(
            // เรียกใช้เครื่องมือ NumberFormatter จัดการเติมจุดทศนิยม 2 ตำแหน่ง
            '${NumberFormatter.money(price.pricePerKg)}/กก.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryGreen,
              fontSize: PriceStyle.cardPriceFontSize,
            ),
          ),
        ],
      ),
    );
  }
}
