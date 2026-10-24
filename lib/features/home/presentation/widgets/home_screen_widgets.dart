import 'dart:io'; // นำเข้าไลบรารีสำหรับจัดการไฟล์ (เอาไว้เช็คว่ารูปภาพมีอยู่ในเครื่องไหม)
import 'package:flutter/material.dart'; // นำเข้าเครื่องมือสร้างหน้าตาแอปของ Flutter

import '../../../../core/constants/app_colors.dart'; // ดึงชุดสีที่เราตั้งค่าไว้มาใช้
import '../../../../core/utils/number_formatter.dart'; // ดึงตัวช่วยแปลงตัวเลข (เช่น ใส่ลูกน้ำให้เงิน)
import '../../../../features/history/data/models/history_record_model.dart'; // ดึงโครงสร้างข้อมูลประวัติการสแกน

// ===========================================================================
// HomeStyle : ศูนย์ควบคุมขนาดและฟอนต์ (แก้เลขตรงนี้ หน้าแอปจะเปลี่ยนตาม)
// ===========================================================================
class HomeStyle {
  HomeStyle._();

  // ---------- กลุ่มปุ่มสแกนสีเขียวใหญ่ ----------
  // ถ้าต้องการกำหนดขนาดเอง ให้เปลี่ยน null เป็นตัวเลข เช่น 24
  static const double? heroTitleFontSize = null;
  static const double? heroSubtitleFontSize = 15;

  // ---------- กลุ่มการ์ดสถิติ 4 ใบ ----------
  // สัดส่วนการ์ด: เลขยิ่งน้อย (เช่น 1.0) การ์ดจะยิ่งทรงสูง, เลขมาก (เช่น 1.5) การ์ดจะทรงกว้าง
  static const double statCardAspectRatio = 1.25;
  static const double statIconSize = 36; // ขนาดไอคอนรูปต่างๆ
  static const double? statValueFontSize = null; // ขนาดตัวเลข (เช่น 2,335.00)
  static const double? statLabelFontSize = 17; // ขนาดข้อความ (เช่น จำนวนรายการ)

  // ---------- กลุ่มปุ่มกด "ดูสถิติ" / "ราคารับซื้อ" ----------
  static const double actionButtonHeight = 58; // ความสูงของปุ่ม
  static const double? actionButtonFontSize = 20;

  // ---------- กลุ่มหัวข้อ "ประวัติล่าสุด" ----------
  static const double? sectionTitleFontSize = null;
  static const double sectionActionFontSize = 16;

  // ---------- กลุ่มการ์ดรายการประวัติ ----------
  static const double historyImageSize = 86; // ขนาดกว้าง/ยาว ของรูปภาพวัสดุ
  static const double? historyTitleFontSize = 20;
  static const double? historyDetailFontSize = 15;
  static const double? historyMetaFontSize = 15;
  static const double? historyNoteFontSize = 15;
}

// ===========================================================================
// ส่วนที่ 1: ส่วนหัวต้อนรับ (ตอนนี้เว้นว่างไว้เผื่อใส่อะไรในอนาคต)
// ===========================================================================
class HomeAppIntro extends StatelessWidget {
  const HomeAppIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 16), // เว้นระยะขอบซ้าย 16 พิกเซล
        Expanded(child: Column()), // ดันพื้นที่ให้เต็ม (เว้นที่ว่างไว้)
      ],
    );
  }
}

// ===========================================================================
// ส่วนที่ 2: การ์ดปุ่มสแกนสีเขียวขนาดใหญ่ (HomeScanHeroCard)
// ===========================================================================
class HomeScanHeroCard extends StatelessWidget {
  const HomeScanHeroCard({required this.onTap, super.key});

  final VoidCallback onTap; // รับคำสั่งเมื่อมีการกดปุ่ม

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryGreen, // เปลี่ยนสีพื้นหลังของปุ่มใหญ่ตรงนี้
      borderRadius: BorderRadius.circular(
        34,
      ), // ความโค้งของมุม (อาจารย์สั่งให้เหลี่ยมขึ้น ให้ลดเลขนี้)
      child: InkWell(
        onTap: onTap, // ทำให้กดแล้วมีเอฟเฟกต์น้ำกระเพื่อม
        borderRadius: BorderRadius.circular(
          34,
        ), // เอฟเฟกต์กดต้องโค้งเท่ากับปุ่ม
        child: Container(
          padding: const EdgeInsets.all(22), // ระยะห่างเนื้อหาด้านในกับขอบปุ่ม
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              // สร้างเงาให้ปุ่มดูมีมิติ
              BoxShadow(
                color: AppColors.primaryGreen.withValues(
                  alpha: 0.22,
                ), // สีเงาเขียวอ่อน 22%
                blurRadius: 28, // ความเบลอของเงา ยิ่งมากยิ่งฟุ้ง
                offset: const Offset(0, 14), // ทิศทางเงา (ดันลงล่าง 14 พิกเซล)
              ),
            ],
          ),
          child: Row(
            children: [
              // 2.1 กล่องสี่เหลี่ยมสีขาวที่ใส่ไอคอนกล้อง
              Container(
                height: 74,
                width: 74, // ขนาดกล่องไอคอน
                decoration: BoxDecoration(
                  color: Colors.white, // สีพื้นหลังกล่องไอคอน
                  borderRadius: BorderRadius.circular(28), // ความโค้งกล่องไอคอน
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ), // เส้นขอบบางๆ
                ),
                child: const Icon(
                  Icons
                      .camera_alt_rounded, // เปลี่ยนรูปไอคอนตรงนี้ (พิมพ์ Icons. แล้วเลือก)
                  color: AppColors.primaryGreen,
                  size: 40,
                ),
              ),

              const SizedBox(
                width: 18,
              ), // ช่องว่างคั่นระหว่างกล้องกับตัวหนังสือ
              // 2.2 พื้นที่ตัวหนังสือ (ใช้ Expanded ดันให้ข้อความเต็มพื้นที่ตรงกลาง)
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // จัดให้ข้อความชิดซ้าย
                  children: [
                    // ข้อความบรรทัดบน
                    Text(
                      'ถ่ายภาพเพื่อสเเกน', // แก้คำตรงนี้
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight
                                .w900, // ความหนาของฟอนต์ (w900 = หนาสุด)
                            color: Colors.white, // สีข้อความ
                            letterSpacing:
                                -0.4, // บีบช่องไฟตัวอักษรให้ชิดกันนิดนึง
                            fontSize: HomeStyle
                                .heroTitleFontSize, // เรียกขนาดจาก HomeStyle
                          ),
                    ),
                    const SizedBox(height: 5), // ช่องว่างระหว่างบรรทัด
                    // ข้อความบรรทัดล่าง
                    Text(
                      'ถ่ายภาพหรือเลือกรูปจากคลังรูปภาพ', // แก้คำตรงนี้
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w500,
                        fontSize: HomeStyle.heroSubtitleFontSize,
                      ),
                    ),
                  ],
                ),
              ),

              // 2.3 ไอคอนลูกศรชี้ขวา ริมสุด
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ส่วนที่ 3: ตารางสถิติ 4 กล่อง (HomeDashboardGrid)
// ===========================================================================
class HomeDashboardGrid extends StatelessWidget {
  const HomeDashboardGrid({
    required this.totalRecords,
    required this.totalEstimatedValue,
    required this.totalCo2Saved,
    required this.totalPoints,
    super.key,
  });

  final int totalRecords;
  final double totalEstimatedValue;
  final double totalCo2Saved;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2, // แบ่งเป็น 2 คอลัมน์ (อยากได้ 3 คอลัมน์ แก้เลขนี้)
      shrinkWrap: true, // ทำให้ Grid หดตัวพอดีกับเนื้อหา ไม่เกิด Error ทะลุจอ
      physics:
          const NeverScrollableScrollPhysics(), // ปิดไม่ให้ตัวนี้เลื่อนได้ (ให้เลื่อนที่ตัวแม่แทน)
      mainAxisSpacing: 14, // ระยะห่างแนวตั้งระหว่างกล่อง
      crossAxisSpacing: 14, // ระยะห่างแนวนอนระหว่างกล่อง
      childAspectRatio:
          HomeStyle.statCardAspectRatio, // ดึงสัดส่วนจาก HomeStyle
      children: [
        // ลำดับกล่องที่ 1
        HomeStatCard(
          icon: Icons.history_rounded,
          value: '$totalRecords',
          label: 'จำนวนรายการ',
        ),
        // ลำดับกล่องที่ 2
        HomeStatCard(
          icon: Icons.account_balance_wallet_rounded,
          value: NumberFormatter.money(totalEstimatedValue),
          label: 'มูลค่าประเมิน',
        ),
        // ลำดับกล่องที่ 3
        HomeStatCard(
          icon: Icons.eco_rounded,
          value: NumberFormatter.co2(totalCo2Saved),
          label: 'CO₂ ที่ลดได้',
        ),
        // ลำดับกล่องที่ 4
        HomeStatCard(
          icon: Icons.star_rounded,
          value: '$totalPoints',
          label: 'คะแนนสะสม',
        ),
        // ** ถ้าอาจารย์ให้สลับตำแหน่งกล่อง ให้ Cut แล้ว Paste สลับบรรทัดกันได้เลย! **
      ],
    );
  }
}

// ===========================================================================
// ส่วนที่ 4: หน้าตาของการ์ดสถิติ 1 กล่อง (HomeStatCard)
// ===========================================================================
class HomeStatCard extends StatelessWidget {
  const HomeStatCard({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardGreen, // สีพื้นหลังของการ์ด
        borderRadius: BorderRadius.circular(26), // ความโค้งของการ์ด
        border: Border.all(color: AppColors.cardBorder), // สีเส้นขอบการ์ด
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // จัดทุกอย่างให้ชิดซ้าย
        children: [
          Icon(
            icon,
            size: HomeStyle.statIconSize,
            color: AppColors.darkGreen,
          ), // ไอคอน
          const Spacer(), // *ตัวดัน* มันจะทำตัวเป็นสปริง ดันไอคอนขึ้นบนสุด ดันข้อความลงล่างสุด
          Text(
            value, // ค่าตัวเลขที่รับมา
            maxLines: 1, // บังคับแสดง 1 บรรทัด
            overflow:
                TextOverflow.ellipsis, // ถ้าตัวเลขยาวไป ให้แสดง ... ตอนท้าย
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              fontSize: HomeStyle.statValueFontSize,
            ),
          ),
          const SizedBox(height: 3), // ระยะห่างตัวเลขกับคำอธิบาย
          Text(
            label, // ข้อความกำกับ (เช่น 'จำนวนรายการ')
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMutedSecondary,
              fontWeight: FontWeight.w600,
              fontSize: HomeStyle.statLabelFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ส่วนที่ 5: ปุ่มกดยาวๆ ("ดูสถิติ" / "ราคารับซื้อ") (HomeSecondaryActionButton)
// ===========================================================================
class HomeSecondaryActionButton extends StatelessWidget {
  const HomeSecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed, // เวลากดให้ทำงานตามที่ส่งมา
      style: FilledButton.styleFrom(
        backgroundColor: const Color(
          0xFF35C21B,
        ), // แก้สีปุ่มตรงนี้ (0xFF คือค่าโปร่งใส 100%, ตามด้วยโค้ดสี HEX)
        foregroundColor: Colors.white, // สีตัวหนังสือและไอคอนในปุ่ม
        minimumSize: const Size.fromHeight(
          HomeStyle.actionButtonHeight,
        ), // บังคับความสูงปุ่ม
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ), // มุมโค้งของปุ่ม
        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: HomeStyle.actionButtonFontSize,
        ),
      ),
      icon: Icon(icon, size: 30), // ไอคอนในปุ่ม
      label: Text(label), // ข้อความในปุ่ม
    );
  }
}

// ===========================================================================
// ส่วนที่ 6: แถบหัวข้อพร้อมปุ่ม "ดูทั้งหมด" (HomeSectionHeader)
// ===========================================================================
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    super.key,
  });
  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ใช้ Expanded ครอบหัวข้อ เพื่อดันปุ่ม 'ดูทั้งหมด' ไปชิดขวาสุดหน้าจอ
        Expanded(
          child: Text(
            title, // คำว่า "ประวัติล่าสุด"
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: AppColors.textDark,
              fontSize: HomeStyle.sectionTitleFontSize,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel, // คำว่า "ดูทั้งหมด"
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w900,
              fontSize: HomeStyle.sectionActionFontSize,
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// ส่วนที่ 7: กล่องแสดงประวัติ 1 รายการ (HomeRecentHistoryCard)
// ===========================================================================
class HomeRecentHistoryCard extends StatelessWidget {
  const HomeRecentHistoryCard({required this.record, super.key});
  final HistoryRecordModel record; // ข้อมูลที่ดึงมาจาก SQLite 1 แถว

  @override
  Widget build(BuildContext context) {
    // โค้ดป้องกันบั๊ก! ตรวจสอบว่ารูปภาพที่เคยเซฟไว้ ตอนนี้ไฟล์ยังอยู่ในมือถือไหม
    final bool hasImage = File(record.imagePath).existsSync();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardGreen, // สีพื้นหลังการ์ดประวัติ
        borderRadius: BorderRadius.circular(30), // ขอบโค้ง
        border: Border.all(color: AppColors.cardBorder), // สีเส้นขอบ
      ),
      child: Row(
        children: [
          // 7.1 กรอบรูปภาพทางซ้าย
          ClipRRect(
            borderRadius: BorderRadius.circular(22), // ตัดขอบรูปภาพให้โค้ง
            // เช็คว่ามีรูปไหม (hasImage)
            // ถ้ามี (?) ให้แสดง Image.file
            // ถ้าไม่มี (:) ให้สร้างกล่องว่างๆ สีขาว ใส่ไอคอนรูปภาพแทน (กันแอปพัง)
            child: hasImage
                ? Image.file(
                    File(record.imagePath),
                    width: HomeStyle.historyImageSize,
                    height: HomeStyle.historyImageSize,
                    fit:
                        BoxFit.cover, // ให้รูปขยายเต็มกรอบพอดีโดยไม่เสียสัดส่วน
                  )
                : Container(
                    width: HomeStyle.historyImageSize,
                    height: HomeStyle.historyImageSize,
                    color: Colors.white,
                    child: const Icon(
                      Icons.image_outlined,
                    ), // ไอคอนแสดงกรณีหารูปไม่เจอ
                  ),
          ),

          const SizedBox(width: 14), // ระยะห่างรูปภาพกับข้อความ
          // 7.2 ส่วนรายละเอียดทางขวา
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ชื่อวัสดุ เช่น "พลาสติก PET"
                Text(
                  record.material,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    fontSize: HomeStyle.historyTitleFontSize,
                  ),
                ),
                const SizedBox(height: 4),
                // น้ำหนักและราคา
                Text(
                  // ใช้ toStringAsFixed(2) บังคับโชว์ทศนิยม 2 ตำแหน่ง
                  '${record.weight.toStringAsFixed(2)} กก. • ${NumberFormatter.money(record.estimatedPrice)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: HomeStyle.historyDetailFontSize,
                  ),
                ),
                const SizedBox(height: 4),
                // ค่า CO2 และ คะแนน
                Text(
                  // จุดที่แก้บั๊กจากการตัดบรรทัด (ใช้จุดกลม • คั่นแทน \n เพื่อความปลอดภัย)
                  '${NumberFormatter.co2(record.co2Saved)} • ${record.pointsEarned} คะแนน',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: HomeStyle.historyMetaFontSize,
                  ),
                ),

                // 7.3 หมายเหตุ (โชว์เฉพาะเวลามีข้อมูลเท่านั้น)
                // ตรวจสอบว่า record.note ไม่เป็น null และไม่เป็นข้อความว่างๆ
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 4), // ระยะห่างด้านบนหมายเหตุ
                  Text(
                    record.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMutedSecondary,
                      fontSize: HomeStyle.historyNoteFontSize,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// ส่วนที่ 8: วงกลมโหลดข้อมูล (HomeLoadingHistoryCard)
// ===========================================================================
class HomeLoadingHistoryCard extends StatelessWidget {
  const HomeLoadingHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
      ),
      // CircularProgressIndicator คือตัวหมุนๆ โหลดข้อมูล
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

// ===========================================================================
// ส่วนที่ 9: หน้าตาตอน "ยังไม่มีประวัติการสแกน" (HomeEmptyRecentHistory)
// ===========================================================================
class HomeEmptyRecentHistory extends StatelessWidget {
  const HomeEmptyRecentHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 34,
      ), // ระยะขอบด้านใน
      decoration: BoxDecoration(
        color: AppColors.cardGreen, // กล่องพื้นหลัง
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          // ไอคอนกล่องว่างเปล่า
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48), // สีขาวโปร่งใส
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.inventory_2_outlined, // เปลี่ยนไอคอนตรงนี้ได้
              size: 34,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16), // เว้นระยะ
          // ข้อความหลัก
          Text(
            'ยังไม่มีรายการ', // แกัคำตรงนี้ได้
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8), // เว้นระยะ
          // ข้อความรอง
          Text(
            'เริ่มต้นด้วยการสแกนวัสดุรีไซเคิลชิ้นแรกของคุณ', // แก้คำตรงนี้ได้
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMutedSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center, // จัดให้อยู่กึ่งกลาง
          ),
        ],
      ),
    );
  }
}
