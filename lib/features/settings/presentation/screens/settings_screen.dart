// 💡 บรรทัดที่ถูกคอมเมนต์ (//) คือโค้ดที่ปิดการทำงานไว้ (ในที่นี้คือโหมด Debug ของนักพัฒนา)
//import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart'; // นำเข้าชุดเครื่องมือวาดหน้าจอ (UI) ของ Flutter

import '../../../../core/constants/app_colors.dart'; // นำเข้าไฟล์สีหลักของแอป
import '../../../../features/history/data/repositories/history_repository.dart'; // นำเข้าตัวคุยกับ Database สำหรับจัดการตารางประวัติ
import '../../../../services/database/app_database.dart'; // นำเข้าตัวเชื่อมต่อฐานข้อมูลหลัก SQLite
//import '../../../../services/database/database_debug_screen.dart'; // นำเข้าหน้าต่างเช็ค DB (ปิดไว้ไม่ได้ใช้)

// ===========================================================================
// หน้าตั้งค่า (StatefulWidget) : เป็น Stateful เพราะหน้านี้มีปุ่มกดลบข้อมูล
// เวลาลบข้อมูลต้องโชว์ "ตัวหมุนโหลด" จึงต้องมีการเปลี่ยนแปลงสถานะหน้าจอ
// ===========================================================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key}); // คอนสตรัคเตอร์เริ่มต้น

  @override
  State<SettingsScreen> createState() => _SettingsScreenState(); // ผูกติดกับ State ของมัน
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 💡 late = สัญญาณบอกว่า "เดี๋ยวจะใส่ค่าให้ทีหลัง (ใน initState) แต่ตอนใช้งานรับรองว่ามีค่าแน่นอน"
  // 💡 final = กำหนดค่าให้ตัวนี้ได้แค่ครั้งเดียว เปลี่ยนไปเชื่อม DB ก้อนอื่นไม่ได้แล้ว
  late final HistoryRepository _historyRepository;

  // 💡 ตัวแปร State (สวิตช์หน้าจอ): กำลังโหลดลบข้อมูลอยู่หรือไม่?
  bool _isClearing = false;

  // ฟังก์ชันตั้งต้น (ทำงานครั้งเดียวถ้วนตอนเปิดหน้านี้ขึ้นมา)
  @override
  void initState() {
    super.initState(); // เรียกใช้งานระบบพื้นฐานของ Flutter
    // โอนพลังเชื่อมต่อ DB (AppDatabase.instance) ไปให้ _historyRepository
    _historyRepository = HistoryRepository(database: AppDatabase.instance);
  }

  // ===========================================================================
  // 🗑️ ฟังก์ชันหลัก: ถามยืนยัน -> ลบข้อมูล -> แจ้งเตือน
  // (Future<void> แปลว่าเป็นฟังก์ชันแบบ Asynchronous ที่ต้องรอเวลาทำงาน และไม่มีการส่งค่ากลับไปให้ใคร)
  // ===========================================================================
  Future<void> _clearAllHistory() async {
    // 💡 1) สั่งเปิดป๊อปอัปแจ้งเตือน (AlertDialog) ขึ้นมาขวางหน้าจอ
    // await = โค้ดจะหยุดรอตรงนี้ จนกว่าผู้ใช้จะกดปุ่มใดปุ่มหนึ่งบนป๊อปอัป แล้วเอาคำตอบกลับมาใส่ใน shouldClear
    final shouldClear = await showDialog<bool>(
      context: context, // เปิดป๊อปอัปบนหน้าจอนี้
      builder: (context) {
        return AlertDialog(
          // วิดเจ็ตกล่องป๊อปอัปของระบบ
          title: const Text('ล้างประวัติทั้งหมดหรือไม่?'), // หัวข้อป๊อปอัป
          content: const Text(
            // ข้อความอธิบาย
            'ข้อมูลรีไซเคิลที่บันทึกไว้ทั้งหมดจะถูกลบออกจากเครื่องนี้',
          ),
          actions: [
            // ปุ่มกดด้านล่างของป๊อปอัป
            // ปุ่ม "ยกเลิก" (แบบเป็นตัวหนังสือธรรมดา)
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                false,
              ), // ถ้ากด ให้ปิดป๊อปอัป และส่งค่า 'false' กลับไป
              child: const Text('ยกเลิก'),
            ),
            // ปุ่ม "ล้างข้อมูล" (แบบเป็นปุ่มทึบสีแดง)
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ), // ถ้ากด ให้ปิดป๊อปอัป และส่งค่า 'true' กลับไป
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ), // เปลี่ยนสีปุ่มเป็นแดง
              child: const Text('ล้างข้อมูล'),
            ),
          ],
        );
      },
    );

    // 💡 2) ประเมินคำตอบ
    // ถ้า shouldClear ไม่เท่ากับ true (เช่น กดยกเลิก หรือแตะพื้นที่ว่างข้างนอกป๊อปอัปให้มันหายไป)
    // ให้ return ออกจากฟังก์ชันไปเลย ไม่ต้องลบข้อมูลใดๆ ทั้งสิ้น
    if (shouldClear != true) return;

    // 💡 3) เข้าสู่กระบวนการลบ
    // สั่งวาดหน้าจอใหม่ ให้ถังขยะหายไป แล้วโชว์วงกลมหมุนแทน
    setState(() => _isClearing = true);

    try {
      // ลองทำคำสั่งในบล็อกนี้ (บล็อกที่อาจจะเกิด Error ได้)
      // สั่งให้พนักงานไปเคลียร์ข้อมูลในฐานข้อมูลให้หมด (คำสั่งนี้ใช้เวลา จึงต้องใส่ await รอ)
      await _historyRepository.clearAllHistory();

      // 💡 [จุดดักบั๊ก] ป้องกันแอปพัง หากผู้ใช้กดปิดหน้าตั้งค่าหนีไปก่อนที่การลบ DB จะเสร็จ
      if (!mounted) return;

      // โชว์ป้าย SnackBar แจ้งเตือนสีดำด้านล่างจอว่า "ล้างประวัติทั้งหมดแล้ว"
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ล้างประวัติทั้งหมดแล้ว')));
    } catch (error) {
      // ถ้าการลบพัง (เช่น DB โดนล็อก) โค้ดจะเด้งมาทำงานตรงนี้แทน
      debugPrint(
        'Failed to clear history: $error',
      ); // พ่น log ลงหลังบ้าน (คนใช้แอปไม่เห็น)

      if (!mounted) return; // เช็คก่อนวาดจออีกรอบ

      // โชว์ป้ายบอกว่าลบไม่สำเร็จ
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ล้างประวัติไม่สำเร็จ')));
    } finally {
      // โค้ดตรงนี้จะรัน "เสมอ" ไม่ว่าจะสำเร็จ (try) หรือพัง (catch)
      if (mounted) {
        // สั่งวาดจอใหม่ เปลี่ยนวงกลมหมุนกลับมาเป็นปุ่มถังขยะตามเดิม
        setState(() => _isClearing = false);
      }
    }
  }

  // ===========================================================================
  // 🎨 โซนวาดหน้าจอ (UI)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background, // ตั้งสีพื้นหลังหน้าจอเป็นสีเทาอ่อน
      appBar: AppBar(
        // แถบชื่อหน้าจอด้านบน
        title: const Text('ตั้งค่า'),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        // พื้นที่ปลอดภัยกันรอยบาก
        child: ListView(
          // ใช้ ListView เพื่อให้เลื่อนขึ้นลงได้
          padding: const EdgeInsets.all(20), // ขอบรอบนอก 20 พิกเซล
          children: [
            // 💡 ชิ้นส่วนที่ 1: กลุ่มกล่อง "แอปพลิเคชัน"
            const _SettingsSection(
              title: 'แอปพลิเคชัน',
              children: [
                _SettingsTile(
                  // แถวที่ 1
                  icon: Icons.wifi_off_rounded, // ไอคอนรูประบุว่าไม่มีไวไฟ
                  title: 'โหมดออฟไลน์',
                  subtitle: 'แอปนี้จัดเก็บข้อมูลทั้งหมดไว้ในเครื่องนี้เท่านั้น',
                ),
              ],
            ),
            const SizedBox(height: 18), // เว้นระยะห่าง
            // 💡 ชิ้นส่วนที่ 2: กลุ่มกล่อง "ข้อมูล"
            _SettingsSection(
              title: 'ข้อมูล',
              children: [
                _SettingsTile(
                  // แถวที่ 1: ปุ่มล้างประวัติ
                  icon: Icons.delete_sweep_rounded, // ไอคอนไม้กวาดถังขยะ
                  title: 'ล้างประวัติทั้งหมด',
                  subtitle: 'ลบข้อมูลรีไซเคิลที่บันทึกไว้ทั้งหมด',
                  // 💡 Ternary Operator (? :) เพื่อสลับวิดเจ็ตฝั่งขวาสุด (trailing)
                  // ถ้า _isClearing (กำลังโหลด) เป็น true ให้โชว์ CircularProgressIndicator (วงกลมหมุน)
                  // ถ้าเป็น false ให้โชว์ IconButton (รูปถังขยะสีแดงที่กดได้)
                  trailing: _isClearing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ), // หนาแค่ 2 พอ
                        )
                      : IconButton(
                          onPressed:
                              _clearAllHistory, // เวลากดให้เรียกฟังก์ชันลบข้อมูล
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: Colors.redAccent,
                        ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 💡 ชิ้นส่วนที่ 3: กลุ่มกล่อง "เกี่ยวกับ"
            const _SettingsSection(
              title: 'เกี่ยวกับ',
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Classifying and Valuing Recyclable Materials',
                  subtitle: 'แอปจำแนกวัสดุรีไซเคิลด้วย AI และประเมินราคาขาย',
                ),
                _SettingsTile(
                  icon: Icons.storage_rounded,
                  title: 'พื้นที่จัดเก็บ',
                  subtitle: 'ฐานข้อมูล SQLite ในเครื่อง ไม่เชื่อมต่อคลาวด์',
                ),
                _SettingsTile(
                  icon: Icons.code_rounded,
                  title: 'เวอร์ชัน',
                  subtitle: '1.0.0',
                ),
              ],
            ),

            // 💡 โค้ดที่โดนปิดคอมเมนต์ (Commented Code)
            // เอาไว้เปิดหน้า DatabaseDebugScreen ตอนทดสอบแอป (ปัจจุบันไม่ได้ใช้แล้ว)
            /* if (kDebugMode) ...[ ... ] */
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 🛠️ ชิ้นส่วน Custom Widget (วาดกรอบการ์ดสำหรับแบ่งกลุ่มการตั้งค่า)
// ===========================================================================
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title; // ชื่อกลุ่มการตั้งค่า (เช่น 'แอปพลิเคชัน', 'ข้อมูล')
  final List<Widget> children; // แถวการตั้งค่าที่จะยัดใส่ลงไปในกลุ่มนี้

  @override
  Widget build(BuildContext context) {
    return Card(
      // กล่องการ์ด
      color: AppColors.cardGreen, // พื้นหลังการ์ดสีเขียวอ่อน
      elevation: 0, // เงาเป็น 0 (แบนราบ)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ), // มุมโค้งการ์ด
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12), // ดันขอบบนล่างด้านใน
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // ตัวหนังสือชิดซ้าย
          children: [
            Padding(
              // หัวข้อของกลุ่ม
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.darkGreen,
                ),
              ),
            ),
            // กระจายชิ้นส่วน children ที่รับมาให้ออกมาเรียงกัน (ใช้ ... Spread Operator)
            ...children,
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 🛠️ ชิ้นส่วน Custom Widget (วาดแถวข้อมูลทีละ 1 บรรทัด เช่น โหมดออฟไลน์)
// ===========================================================================
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon, // รับไอคอน
    required this.title, // รับหัวข้อ
    required this.subtitle, // รับคำอธิบายใต้หัวข้อ
    this.trailing, // รับของที่จะเอาไปวางชิดขวาสุด (เช่น สวิตช์, ถังขยะ) - จะใส่หรือไม่ใส่ก็ได้
    this.onTap, // ฟังก์ชันตอนแตะที่บรรทัดนี้ - จะใส่หรือไม่ใส่ก็ได้
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // ListTile คือวิดเจ็ตสำเร็จรูปของ Flutter สำหรับทำหน้าจอแบบลิสต์
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      // leading: ของที่จะเอาไปวางชิดซ้ายสุด
      leading: Container(
        // สร้างกล่องสี่เหลี่ยมโค้งๆ สีขาวโปร่งใสเอาไว้รองรับไอคอน
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75), // สีขาวความทึบ 75%
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: AppColors.darkGreen,
        ), // ยัดไอคอนสีเขียวไว้ตรงกลาง
      ),
      // title: หัวข้อ (ตัวหนาสีเข้ม)
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
      ),
      // subtitle: คำอธิบาย (ตัวบางสีเทา)
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w500,
        ),
      ),
      // trailing: ของที่จะเอาไปวางชิดขวาสุด (เช่น ปุ่มกดถังขยะ)
      trailing: trailing,
      onTap: onTap, // ถ้าโดนกด ให้ทำอะไร
    );
  }
}
