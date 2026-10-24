import 'package:flutter/material.dart'; // นำเข้าชุดเครื่องมือพื้นฐานของ Flutter สำหรับวาดหน้าจอ (ปุ่ม, ข้อความ, สี)

import '../../../../core/constants/app_colors.dart'; // นำเข้าไฟล์สีประจำแอปที่เราสร้างไว้
import '../../../../core/utils/number_formatter.dart'; // นำเข้าไฟล์ตัวช่วยจัดรูปแบบตัวเลข (เช่น เติมลูกน้ำ)

// ===========================================================================
// คลาส StatisticsStyle เอาไว้เก็บ "ค่าขนาด" เพื่อให้แก้ที่นี่จุดเดียวแล้วเปลี่ยนทั้งหน้า
// ===========================================================================
class StatisticsStyle {
  StatisticsStyle._(); // ปิดไม่ให้คนอื่นสร้างออบเจกต์จากคลาสนี้ซี้ซั้ว

  static const double? appBarTitleFontSize =
      null; // ขนาดตัวหนังสือชื่อหน้าจอ (null = ใช้ขนาดมาตรฐาน)
  static const double summaryCardAspectRatio =
      1.25; // สัดส่วนความกว้างต่อความสูงของกล่องสถิติ 4 อันบน
  static const double summaryIconSize = 33; // ขนาดไอคอนรูปต่างๆ ในกล่องสถิติ
  static const double? summaryValueFontSize =
      20; // ขนาดตัวเลขในกล่อง (เช่น '2', '335.00')
  static const double? summaryLabelFontSize =
      18; // ขนาดตัวหนังสืออธิบายใต้ตัวเลข (เช่น 'จำนวนรายการ')

  static const double sectionIconSize =
      25; // ขนาดไอคอนหน้าหัวข้อ (เช่น ไอคอนกราฟวงกลม)
  static const double? sectionTitleFontSize =
      22; // ขนาดตัวหนังสือหัวข้อใหญ่ (เช่น 'สัดส่วนวัสดุ')

  static const double? listTextFontSize =
      18; // ขนาดตัวหนังสือรายการ (เช่น 'อะลูมิเนียม')
  static const double? listValueFontSize =
      18; // ขนาดตัวเลขรายการ (เช่น '2 รายการ')

  static const double? envTitleFontSize =
      18; // ขนาดตัวหนังสือหัวข้อในการ์ดสีเขียวเข้มล่างสุด
  static const double? envDetailFontSize =
      16; // ขนาดตัวหนังสือคำอธิบายในการ์ดล่างสุด
}

// ===========================================================================
// ชิ้นส่วนที่ 1: ตารางสถิติรวม 4 กล่องบนสุด
// ===========================================================================
class StatisticsSummaryGrid extends StatelessWidget {
  // ฟังก์ชันสร้าง (Constructor) รอรับค่าตัวเลข 4 อย่างมาจากหน้าจอหลัก
  const StatisticsSummaryGrid({
    required this.totalRecords, // รับยอดจำนวนรายการ
    required this.totalEstimatedValue, // รับยอดเงินประเมิน
    required this.totalCo2Saved, // รับยอด CO2
    required this.totalPoints, // รับยอดคะแนน
    super.key, // ส่งคีย์อ้างอิงให้ระบบหลังบ้าน
  });

  // ตัวแปรเก็บค่าที่รับมา
  final int totalRecords;
  final double totalEstimatedValue;
  final double totalCo2Saved;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    // ฟังก์ชันเริ่มวาดหน้าจอ
    return GridView.count(
      // สร้างตาราง (Grid) แบบระบุจำนวนคอลัมน์
      crossAxisCount: 2, // กำหนดให้ตารางมี 2 คอลัมน์ (ซ้าย-ขวา)
      shrinkWrap: true, // บังคับให้ตารางหดตัวพอดีกับเนื้อหา ป้องกันอาการล้นจอ
      physics:
          const NeverScrollableScrollPhysics(), // ปิดไม่ให้ตารางนี้ใช้นิ้วเลื่อนขึ้นลงได้ (กันมันตีกับตัวแม่)
      mainAxisSpacing: 14, // ระยะห่างช่องว่างแนวตั้งระหว่างกล่อง
      crossAxisSpacing: 14, // ระยะห่างช่องว่างแนวนอนระหว่างกล่อง
      childAspectRatio: StatisticsStyle
          .summaryCardAspectRatio, // ดึงสัดส่วนความกว้าง:สูง มาจากด้านบน
      children: [
        // รายการกล่องข้างใน
        // สร้างกล่องที่ 1
        _buildSummaryCard(
          context,
          Icons.history_rounded,
          '$totalRecords',
          'จำนวนรายการ',
        ),
        // สร้างกล่องที่ 2 (💡 ลบคำว่า ' บาท' ออกเพื่อป้องกันการโชว์ซ้ำซ้อน)
        _buildSummaryCard(
          context,
          Icons.payments_outlined,
          NumberFormatter.money(totalEstimatedValue),
          'มูลค่าประเมิน',
        ),
        // สร้างกล่องที่ 3
        _buildSummaryCard(
          context,
          Icons.eco_outlined,
          NumberFormatter.co2(totalCo2Saved),
          'CO₂ ที่ลดได้',
        ),
        // สร้างกล่องที่ 4
        _buildSummaryCard(
          context,
          Icons.star_border_rounded,
          '$totalPoints',
          'คะแนนสะสม',
        ),
      ],
    );
  }

  // ฟังก์ชันส่วนตัว (มี _ นำหน้า) สำหรับสร้างหน้าตากล่อง 1 ใบ (จะได้ไม่ต้องเขียนโค้ดซ้ำ 4 รอบ)
  Widget _buildSummaryCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      // สร้างกล่องสี่เหลี่ยม
      padding: const EdgeInsets.all(
        16,
      ), // เว้นระยะจากขอบกล่องเข้ามาด้านใน 16 พิกเซล
      decoration: BoxDecoration(
        // ตกแต่งกล่อง
        color: AppColors.cardGreen, // ระบายสีพื้นหลังเป็นสีเขียวอ่อน
        borderRadius: BorderRadius.circular(
          20,
        ), // ลบมุมกล่องให้โค้งมน 20 พิกเซล
      ),
      child: Column(
        // จัดเรียงเนื้อหาจากบนลงล่าง
        crossAxisAlignment:
            CrossAxisAlignment.start, // บังคับให้ทุกอย่างในกล่องชิดซ้าย
        mainAxisAlignment: MainAxisAlignment
            .center, // 💡 บังคับให้เนื้อหาทั้งหมดมากองรวมกันตรงกลางกล่องพอดี!
        children: [
          // รายการข้างในกล่อง
          Icon(
            icon,
            size: StatisticsStyle.summaryIconSize,
            color: AppColors.darkGreen,
          ), // วาดไอคอน

          const SizedBox(
            height: 12,
          ), // 💡 เปลี่ยนจาก Spacer() เป็นกำหนดระยะห่างตายตัว 12 พิกเซลแทน

          Text(
            // วาดข้อความตัวเลข
            value, // เอาตัวเลขมาแสดง
            maxLines: 1, // บังคับว่าห้ามขึ้นบรรทัดใหม่ โชว์ได้แค่บรรทัดเดียว
            overflow: TextOverflow
                .ellipsis, // ถ้าตัวเลขยาวทะลุกล่อง ให้ตัดจบด้วยจุด ...
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              // ดึงฟอนต์หลักมาปรับแต่งเพิ่ม
              fontWeight: FontWeight.w900, // ปรับฟอนต์ให้หนาสุดๆ (w900)
              color: AppColors.textDark, // ให้ตัวเลขเป็นสีดำทึบ
              fontSize: StatisticsStyle
                  .summaryValueFontSize, // ดึงขนาดฟอนต์จากตั้งค่า
            ),
          ),
          const SizedBox(height: 4), // เว้นระยะห่างบรรทัด 4 พิกเซล
          Text(
            // วาดข้อความคำอธิบาย
            label, // เอาคำอธิบายมาแสดง (เช่น 'จำนวนรายการ')
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted, // ให้ตัวหนังสือเป็นสีเทาๆ
              fontSize: StatisticsStyle.summaryLabelFontSize, // ดึงขนาดฟอนต์
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 2: กรอบการ์ดใหญ่ๆ สำหรับใส่หัวข้อ (สัดส่วนวัสดุ / กิจกรรมรายเดือน)
// ===========================================================================
class StatisticsSectionCard extends StatelessWidget {
  const StatisticsSectionCard({
    required this.title, // รับข้อความหัวข้อ
    required this.icon, // รับรูปไอคอนหัวข้อ
    required this.child, // รับเนื้อหาที่จะเอามาใส่ข้างใน (Widget)
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child; // Widget คือชิ้นส่วนอะไรก็ได้ (เอาไว้เสียบเนื้อหา)

  @override
  Widget build(BuildContext context) {
    return Container(
      // สร้างกล่องพื้นหลัง
      padding: const EdgeInsets.all(20), // ขอบด้านใน 20
      decoration: BoxDecoration(
        color: AppColors.cardGreen, // พื้นหลังสีเขียวอ่อน
        borderRadius: BorderRadius.circular(24), // มุมโค้ง 24
      ),
      child: Column(
        // เรียงบนลงล่าง
        crossAxisAlignment: CrossAxisAlignment.start, // ชิดซ้าย
        children: [
          Row(
            // แถวบนสุด เรียงซ้ายไปขวา (ไอคอน + ข้อความหัวข้อ)
            children: [
              Icon(
                icon,
                color: AppColors.darkGreen,
                size: StatisticsStyle.sectionIconSize,
              ), // ไอคอนสีเขียวเข้ม
              const SizedBox(width: 8), // เว้นวรรค 8
              Text(
                // ข้อความหัวข้อ
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900, // ตัวหนา
                  color: AppColors.textDark, // สีเข้ม
                  fontSize: StatisticsStyle.sectionTitleFontSize, // ขนาดฟอนต์
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ), // เว้นระยะห่างจากหัวข้อมาหาเนื้อหา 16 พิกเซล
          child, // เอาเนื้อหาที่ส่งมา เสียบวางตรงนี้เลย!
        ],
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 3: รายการพร้อมหลอดเปอร์เซ็นต์ (เอาไว้แสดงสัดส่วนวัสดุ)
// ===========================================================================
class StatisticsDistributionList extends StatelessWidget {
  const StatisticsDistributionList({
    required this.data,
    required this.total,
    super.key,
  });
  final Map<String, int>
  data; // รับตารางข้อมูลมา (เช่น { 'กระดาษ': 5, 'ขวด': 2 })
  final int total; // รับยอดรวมทั้งหมด (เช่น 7) เอาไว้คำนวณความยาวหลอด

  @override
  Widget build(BuildContext context) {
    return Column(
      // เรียงบนลงล่าง
      // ดึงข้อมูลในตาราง (data) มาวนลูป (.map) สร้างบรรทัดทีละอัน
      children: data.entries.map((entry) {
        // คำนวณเปอร์เซ็นต์ (ถ้ายอดรวมมากกว่า 0 เอาชิ้นนั้นหารด้วยยอดรวม, ถ้าไม่ใช่ให้เป็น 0)
        final double percentage = total > 0 ? entry.value / total : 0;
        return Padding(
          // ใส่กรอบเว้นระยะให้แต่ละบรรทัด
          padding: const EdgeInsets.only(
            bottom: 12,
          ), // เว้นระยะด้านล่าง 12 พิกเซล
          child: Column(
            // ใน 1 บรรทัด มีตัวหนังสืออยู่บน หลอดอยู่ล่าง
            children: [
              Row(
                // เรียงตัวหนังสือซ้าย-ขวา
                mainAxisAlignment: MainAxisAlignment
                    .spaceBetween, // ดันข้อความให้แยกไปชิดซ้ายสุดและขวาสุด
                children: [
                  Text(
                    // ข้อความฝั่งซ้าย
                    entry.key, // ชื่อวัสดุ
                    style: TextStyle(
                      fontWeight: FontWeight.w700, // ตัวหนา
                      color: AppColors.textDark, // สีดำ
                      fontSize: StatisticsStyle.listTextFontSize, // ขนาดฟอนต์
                    ),
                  ),
                  Text(
                    // ข้อความฝั่งขวา
                    '${entry.value} รายการ', // จำนวน
                    style: TextStyle(
                      fontWeight: FontWeight.w700, // ตัวหนา
                      color: AppColors.darkGreen, // สีเขียวเข้ม
                      fontSize: StatisticsStyle.listValueFontSize, // ขนาดฟอนต์
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ), // เว้นระยะระหว่างข้อความกับหลอดเปอร์เซ็นต์
              LinearProgressIndicator(
                // สร้างหลอดเปอร์เซ็นต์ (Progress Bar) แนวนอน
                value: percentage, // ความยาวหลอด (รับค่า 0.0 ถึง 1.0)
                backgroundColor: AppColors.darkGreen.withValues(
                  alpha: 0.1,
                ), // สีพื้นหลังหลอด (สีเขียวโปร่งใส 10%)
                color: AppColors.darkGreen, // สีของตัวหลอด (สีเขียวเข้มทึบ)
                minHeight: 8, // ความหนาของหลอด
                borderRadius: BorderRadius.circular(
                  4,
                ), // ลบมุมปลายหลอดให้มนๆ 4 พิกเซล
              ),
            ],
          ),
        );
      }).toList(), // วนลูปเสร็จ ต้องแปลงกลับเป็น List ให้ Column ไปใช้งานต่อได้
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 4: รายการกิจกรรมรายเดือน
// ===========================================================================
class StatisticsMonthlyActivityList extends StatelessWidget {
  const StatisticsMonthlyActivityList({required this.data, super.key});
  final Map<String, int> data; // รับตารางข้อมูลมา (เช่น { '10/2026': 2 })

  @override
  Widget build(BuildContext context) {
    return Column(
      // เรียงบนลงล่าง
      // วนลูปสร้างทีละบรรทัด
      children: data.entries.map((entry) {
        return Padding(
          // เว้นระยะ
          padding: const EdgeInsets.only(bottom: 8), // ห่างข้างล่าง 8
          child: Row(
            // เรียงซ้าย-ขวา
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // ดันซ้ายสุด ขวาสุด
            children: [
              Text(
                // ฝั่งซ้าย
                entry.key, // โชว์เดือน/ปี
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  fontSize: StatisticsStyle.listTextFontSize,
                ),
              ),
              Text(
                // ฝั่งขวา
                '${entry.value} รายการ', // โชว์จำนวน
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkGreen,
                  fontSize: StatisticsStyle.listValueFontSize,
                ),
              ),
            ],
          ),
        );
      }).toList(), // จบลูปแปลงเป็น List
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 5: การ์ดสีเขียวเข้มด้านล่างสุด (ผลกระทบเชิงบวก)
// ===========================================================================
class StatisticsEnvironmentalSummary extends StatelessWidget {
  const StatisticsEnvironmentalSummary({
    required this.totalCo2Saved, // รับยอด CO2
    required this.totalPoints, // รับยอดคะแนน
    super.key,
  });

  final double totalCo2Saved;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      // สร้างกล่อง
      padding: const EdgeInsets.all(20), // ขอบด้านใน 20
      decoration: BoxDecoration(
        // ตกแต่งกล่อง
        color: AppColors.darkGreen, // ใช้สีพื้นหลังเป็น "สีเขียวเข้ม"
        borderRadius: BorderRadius.circular(24), // มุมโค้ง 24
      ),
      child: Column(
        // เรียงบนลงล่าง
        crossAxisAlignment: CrossAxisAlignment.start, // ชิดซ้าย
        children: [
          const Icon(
            Icons.park_rounded,
            color: Colors.white,
            size: 32,
          ), // ไอคอนรูปต้นไม้สีขาว
          const SizedBox(height: 12), // เว้น 12
          Text(
            // บรรทัดหัวข้อ
            'ผลกระทบเชิงบวกต่อสิ่งแวดล้อม',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900, // หนาสุด
              color: Colors.white, // ตัวหนังสือสีขาว
              fontSize: StatisticsStyle.envTitleFontSize, // ขนาดฟอนต์
            ),
          ),
          const SizedBox(height: 8), // เว้น 8
          Text(
            // บรรทัดคำอธิบาย
            // เอาตัวเลข CO2 และ คะแนน มาแทรกในข้อความ
            'คุณลดคาร์บอนได้ ${NumberFormatter.co2(totalCo2Saved)} และได้รับ $totalPoints คะแนนจากกิจกรรมรีไซเคิล',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(
                alpha: 0.9,
              ), // ตัวหนังสือสีขาวโปร่งใส 90%
              height: 1.5, // ความห่างบรรทัด 1.5 เท่า (ให้อ่านง่าย)
              fontSize: StatisticsStyle.envDetailFontSize, // ขนาดฟอนต์
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ชิ้นส่วนที่ 6: ข้อความที่โชว์ตอน "ยังไม่มีข้อมูล"
// ===========================================================================
class StatisticsEmptyText extends StatelessWidget {
  const StatisticsEmptyText(this.message, {super.key});
  final String message; // รับข้อความมา (เช่น 'ยังไม่มีข้อมูลวัสดุ')

  @override
  Widget build(BuildContext context) {
    return Center(
      // จัดข้อความให้อยู่กึ่งกลาง
      child: Padding(
        // เว้นระยะรอบๆ
        padding: const EdgeInsets.all(16.0), // ทุกด้าน 16
        child: Text(
          message, // แสดงข้อความที่รับมา
          style: TextStyle(
            color: AppColors.textMutedSecondary, // สีเทาอ่อน
            fontWeight: FontWeight.w500, // ความหนาปานกลาง
          ),
        ),
      ),
    );
  }
}
