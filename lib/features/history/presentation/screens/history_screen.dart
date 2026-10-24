import 'package:flutter/material.dart'; // นำเข้าชุดเครื่องมือพื้นฐานของ Flutter สำหรับสร้างหน้าจอ (UI)

import '../../../../core/constants/app_colors.dart'; // นำเข้าไฟล์สีประจำแอปที่เราตั้งค่าไว้ (เช่น สีเขียว สีเทา)
import '../../../../core/utils/calculation_utils.dart'; // นำเข้าไฟล์เครื่องคิดเลข (สูตรคำนวณราคาและคาร์บอน)
import '../../../../core/utils/number_formatter.dart'; // นำเข้าไฟล์จัดรูปแบบตัวเลข (เช่น เติมลูกน้ำให้ตัวเลขเงิน)
import '../../data/models/history_record_model.dart'; // นำเข้าโครงสร้างกล่องเก็บข้อมูลประวัติแต่ละรายการ
import '../../data/repositories/history_repository.dart'; // นำเข้าไฟล์สำหรับคุยกับฐานข้อมูล (เซฟ, ดึง, ลบ)
import '../../../../services/database/app_database.dart'; // นำเข้าตัวเชื่อมต่อกับฐานข้อมูล SQLite ในเครื่อง
import '../widgets/history_screen_widgets.dart'; // นำเข้าชิ้นส่วน UI ที่ใช้ในหน้านี้ (เช่น การ์ดประวัติ)
import 'history_detail_screen.dart'; // นำเข้าหน้าจอรายละเอียด (เอาไว้เด้งไปตอนกดที่การ์ดประวัติ)

// ===========================================================================
// หน้าจอประวัติหลัก (เป็น StatefulWidget เพราะต้องมีการกดปุ่มแล้วหน้าจอเปลี่ยน)
// ===========================================================================
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key}); // คอนสตรัคเตอร์ของหน้าจอ

  @override
  State<HistoryScreen> createState() => _HistoryScreenState(); // สร้าง State สำหรับเก็บข้อมูลและควบคุมหน้าจอนี้
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryRepository
  _historyRepository; // ตัวแปรสำหรับเรียกใช้คำสั่งดึง/ลบข้อมูลจากฐานข้อมูล

  List<HistoryRecordModel> _records =
      []; // ตัวแปรแบบ List (อาร์เรย์) สำหรับเก็บประวัติ "ทั้งหมด" ที่โหลดมาจากฐานข้อมูล
  bool _isLoading =
      true; // ตัวแปรเช็คว่า "กำลังโหลดข้อมูลอยู่ไหม?" (ค่าเริ่มต้นคือ true = โหลดอยู่)

  // 📌 1. ตัวแปรเก็บว่า ตอนนี้ผู้ใช้กำลังกดดูหมวดหมู่ไหนอยู่
  // 0 = โชว์ทั้งหมด | 1 = รอใส่น้ำหนัก | 2 = ประวัติวัสดุ | 3 = รายได้
  int _selectedFilterIndex = 0;

  // 📌 2. ตัวแปรแบบ List เก็บชื่อของ "ปุ่มหมวดหมู่" ที่จะโชว์ด้านบน (เรียงตาม Index 0, 1, 2, 3)
  final List<String> _filterNames = [
    'ทั้งหมด', // Index 0
    'รอใส่น้ำหนัก', // Index 1
    'ประวัติวัสดุ', // Index 2
    'รายได้', // Index 3
  ];

  @override
  void initState() {
    // ฟังก์ชันที่จะทำงาน "แค่ครั้งเดียว" ตอนเปิดหน้านี้ขึ้นมา
    super.initState();
    _historyRepository = HistoryRepository(
      database: AppDatabase.instance,
    ); // เชื่อมต่อกับฐานข้อมูล
    _loadHistory(); // สั่งให้ไปโหลดประวัติมาแสดง
  }

  // ===========================================================================
  // 📡 ฟังก์ชันดึงข้อมูลจาก Database
  // ===========================================================================
  Future<void> _loadHistory() async {
    // ใช้ async เพราะต้องรอโหลดข้อมูลจากเครื่อง
    try {
      // ลองทำงานในบล็อกนี้
      final records = await _historyRepository
          .getAllHistory(); // ไปดึงประวัติทั้งหมดมาเก็บไว้ในตัวแปร records
      if (!mounted)
        return; // เช็คว่าผู้ใช้กดปิดหน้านี้หนีไปหรือยัง ถ้าปิดไปแล้วให้หยุดทำงานทันที

      setState(() {
        // สั่งอัปเดตหน้าจอ
        _records = records; // เอาข้อมูลที่โหลดมา ใส่เข้าไปในตัวแปรของหน้าจอ
        _isLoading = false; // ปิดสถานะกำลังโหลด (ให้วงกลมหมุนๆ หายไป)
      });
    } catch (error) {
      // ถ้าโหลดพัง (เช่น ฐานข้อมูลมีปัญหา)
      debugPrint(
        'Failed to load history: $error',
      ); // พ่นข้อความแจ้งเตือนลงในหน้าต่างนักพัฒนา
      if (!mounted) return; // เช็คว่าหน้าจอยังเปิดอยู่ไหม

      setState(() {
        // สั่งอัปเดตหน้าจอ
        _records = []; // ให้ประวัติเป็นรายการว่างเปล่า
        _isLoading = false; // ปิดสถานะกำลังโหลด
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โหลดประวัติไม่สำเร็จ')),
      ); // โชว์แถบแจ้งเตือนสีดำด้านล่าง
    }
  }

  // ===========================================================================
  // 🗑️ ฟังก์ชันสำหรับ "ลบประวัติ" เมื่อกดปุ่มถังขยะ
  // ===========================================================================
  Future<void> _deleteRecord(HistoryRecordModel record) async {
    if (record.id == null)
      return; // ถ้าข้อมูลนี้ไม่มี ID แสดงว่าผิดปกติ ให้หยุดการลบ

    // แสดงหน้าต่าง Pop-up ถามเพื่อความแน่ใจ
    final shouldDelete = await showDialog<bool>(
      context: context, // แหล่งอ้างอิงหน้าจอ
      builder: (context) {
        // สร้างหน้าต่าง Pop-up
        return AlertDialog(
          // วิดเจ็ตหน้าต่างแจ้งเตือน
          title: const Text('ลบรายการนี้หรือไม่?'), // หัวข้อ Pop-up
          content: const Text(
            'รายการนี้จะถูกลบออกจากประวัติในเครื่องของคุณ',
          ), // ข้อความอธิบาย
          actions: [
            // ปุ่มด้านล่างของ Pop-up
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ), // ปุ่มยกเลิก ส่งค่า false กลับไป
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ'),
            ), // ปุ่มยืนยันลบ ส่งค่า true กลับไป
          ],
        );
      },
    );

    if (shouldDelete != true)
      return; // ถ้าผู้ใช้ไม่ได้กด "ลบ" (ค่าไม่ใช่ true) ให้ยกเลิกการทำงานไปเลย

    await _historyRepository.deleteHistory(
      record.id!,
    ); // สั่งลบข้อมูลออกจากฐานข้อมูลจริงๆ
    if (!mounted) return; // เช็คว่าหน้าจอยังเปิดอยู่ไหม

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ลบรายการแล้ว')),
    ); // โชว์ข้อความว่าลบสำเร็จ
    await _loadHistory(); // 🔄 โหลดข้อมูลใหม่ทั้งหมด เพื่อให้รายการที่ลบหายไปจากจอ
  }

  // ===========================================================================
  // ⚖️ ฟังก์ชัน "ยืนยันน้ำหนัก" สำหรับรายการที่ค้างไว้
  // ===========================================================================
  Future<void> _confirmWeight(HistoryRecordModel record, double weight) async {
    if (record.id == null) return; // ป้องกันบั๊กถ้าไม่มี ID

    // คำนวณราคาใหม่: เอาน้ำหนักที่เพิ่งกรอก ไปคูณกับราคาต่อกก. ที่เคยเซฟไว้
    final estimatedPrice = CalculationUtils.calculateEstimatedPrice(
      weightKg: weight,
      pricePerKg: record.pricePerKg,
    );
    // คำนวณคาร์บอนใหม่: เอาน้ำหนักที่เพิ่งกรอก ไปคูณกับค่าคงที่คาร์บอน ที่เคยเซฟไว้
    final co2Saved = CalculationUtils.calculateCo2Saved(
      weightKg: weight,
      co2Factor: record.co2FactorPerKg,
    );

    // สร้างข้อมูลชุดใหม่ (Copy) โดยเอาข้อมูลเดิมมา แล้วอัปเดตแค่น้ำหนัก ราคา คาร์บอน และคะแนน
    final updated = record.copyWith(
      weight: weight, // อัปเดตน้ำหนัก
      estimatedPrice: estimatedPrice, // อัปเดตราคาที่คำนวณใหม่
      co2Saved: co2Saved, // อัปเดตคาร์บอน
      pointsEarned: CalculationUtils.calculatePoints(co2Saved), // อัปเดตคะแนน
    );

    await _historyRepository.updateHistory(
      updated,
    ); // สั่งเซฟข้อมูลที่อัปเดตแล้วลงฐานข้อมูลทับของเดิม
    if (!mounted) return; // เช็คหน้าจอ
    await _loadHistory(); // 🔄 โหลดข้อมูลใหม่ เพื่อให้การ์ดที่เพิ่งใส่น้ำหนัก เปลี่ยนสีเป็นสมบูรณ์
  }

  // ===========================================================================
  // 🎨 โซนสร้างหน้าตา UI หลักของหน้านี้
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // ฟังก์ชันที่ทำหน้าที่วาดหน้าจอ
    return Scaffold(
      // โครงสร้างหน้าจอหลัก
      backgroundColor:
          AppColors.background, // กำหนดสีพื้นหลังของแอป (ดึงจากที่ตั้งค่าไว้)
      appBar: AppBar(
        // แถบชื่อหน้าจอด้านบน
        title: const Text('ประวัติ'), // ข้อความหัวข้อ
        backgroundColor: AppColors.background, // สีพื้นหลังแถบด้านบน
        actions: [
          // ปุ่มที่อยู่มุมขวาบนของ AppBar
          IconButton(
            // ปุ่มแบบมีแต่ไอคอน
            tooltip: 'รีเฟรช', // คำอธิบายเวลากดค้าง
            onPressed: _loadHistory, // พอกดแล้วให้เรียกฟังก์ชันโหลดข้อมูลใหม่
            icon: const Icon(Icons.refresh_rounded), // ไอคอนลูกศรหมุนๆ
          ),
        ],
      ),
      body: SafeArea(
        // พื้นที่ปลอดภัย (ไม่ให้เนื้อหาไปทับรอยบาก หรือติ่งกล้องมือถือ)
        child: Column(
          // จัดเรียงเนื้อหาจากบนลงล่าง
          children: [
            // 📌 3. วาดแถบปุ่มเลื่อนด้านบน (เรียกฟังก์ชัน _buildFilterChips)
            _buildFilterChips(),

            // 📌 4. พื้นที่แสดงข้อมูลการ์ดประวัติ (ใช้ Expanded เพื่อให้กินพื้นที่จอที่เหลือทั้งหมดจนถึงขอบล่าง)
            Expanded(
              child: RefreshIndicator(
                // วิดเจ็ตที่ทำให้ผู้ใช้ใช้นิ้ว "ดึงจอลง" เพื่อรีเฟรชได้
                onRefresh:
                    _loadHistory, // พอดึงจอลง ให้เรียกฟังก์ชันโหลดประวัติ
                child:
                    _buildBody(), // ตรงนี้คือการเรียกฟังก์ชัน _buildBody เพื่อดึงเนื้อหามาวาด
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🌟 ชิ้นส่วน: แถบปุ่มหมวดหมู่ (Filter Chips) ที่อยู่ด้านบนสุด
  // ---------------------------------------------------------------------------
  Widget _buildFilterChips() {
    return SizedBox(
      // ใช้กรอบจำกัดความสูง
      height: 60, // กำหนดความสูงของแถบปุ่มไว้ที่ 60 พิกเซล
      child: ListView.builder(
        // สร้างลิสต์รายการแบบวนลูป
        scrollDirection: Axis
            .horizontal, // บังคับให้ลิสต์นี้ใช้นิ้วเลื่อน "ซ้าย-ขวา" ได้ (แนวนอน)
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 8,
        ), // เว้นขอบซ้ายขวา 20 บนล่าง 8
        itemCount: _filterNames
            .length, // จำนวนปุ่มที่จะสร้าง (เท่ากับจำนวนชื่อใน _filterNames คือ 4 อัน)
        itemBuilder: (context, index) {
          // ฟังก์ชันสร้างปุ่มทีละปุ่ม (index คือเลขลำดับ 0,1,2,3)
          final isSelected =
              _selectedFilterIndex ==
              index; // เช็คว่าปุ่มที่กำลังวาดนี้ คือปุ่มที่ผู้ใช้กดเลือกไว้หรือไม่? (ถ้าใช่จะเป็น true)

          return Padding(
            // เว้นระยะห่างของปุ่ม
            padding: const EdgeInsets.only(
              right: 8,
            ), // ให้ปุ่มแต่ละอันเว้นห่างกันด้านขวา 8 พิกเซล
            child: FilterChip(
              // วิดเจ็ตปุ่มแคปซูลวงรี
              label: Text(
                _filterNames[index],
              ), // ข้อความบนปุ่ม (ดึงมาจากตัวแปร Array ด้านบน)
              selected:
                  isSelected, // บอกวิดเจ็ตว่า ตอนนี้ปุ่มนี้ถูกเลือกอยู่ไหม?
              selectedColor: AppColors
                  .cardGreen, // 🎨 สีพื้นหลังของปุ่ม 'ตอนที่ถูกเลือก' (สีเขียวอ่อน)
              checkmarkColor: AppColors
                  .darkGreen, // 🎨 สีของติ๊กถูกหน้าข้อความ 'ตอนที่ถูกเลือก'
              labelStyle: TextStyle(
                // สไตล์ตัวหนังสือในปุ่ม
                color: isSelected
                    ? AppColors.darkGreen
                    : AppColors
                          .textDark, // ถ้าถูกเลือกให้เป็นสีเขียวเข้ม ถ้าไม่เลือกให้เป็นสีดำ
                fontWeight: isSelected
                    ? FontWeight.w800
                    : FontWeight
                          .w500, // ถ้าถูกเลือกให้ตัวหนังสือ 'หนา' ถ้าไม่เลือกให้ความหนาปานกลาง
              ),
              backgroundColor: Colors
                  .white, // 🎨 สีพื้นหลังปุ่ม 'ตอนที่ยังไม่ได้เลือก' (สีขาว)
              shape: RoundedRectangleBorder(
                // กำหนดรูปทรงปุ่ม
                borderRadius: BorderRadius.circular(
                  20,
                ), // ลบมุมปุ่มให้โค้งมน 20 พิกเซล
                side: BorderSide(
                  // กำหนดเส้นขอบปุ่ม
                  color: isSelected
                      ? AppColors.darkGreen
                      : AppColors
                            .cardBorder, // ถ้าเลือกเส้นขอบสีเขียวเข้ม ถ้าไม่เลือกเส้นขอบสีเทาอ่อน
                  width: isSelected
                      ? 1.5
                      : 1.0, // ถ้าเลือกให้เส้นขอบหนา 1.5 ถ้าไม่เลือกให้หนาแค่ 1
                ),
              ),
              onSelected: (selected) {
                // ฟังก์ชันทำงานเมื่อผู้ใช้เอานิ้วกดปุ่มนี้
                setState(() {
                  // สั่งให้หน้าจอรับรู้ว่ามีการเปลี่ยนแปลง แล้ววาดจอใหม่
                  _selectedFilterIndex =
                      index; // เปลี่ยนตัวแปรให้จำว่า ตอนนี้กดปุ่มหมายเลขอะไรอยู่ (0, 1, 2, หรือ 3)
                });
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🌟 ชิ้นส่วน: พื้นที่โชว์เนื้อหาตรงกลางจอ (กรองข้อมูลตามปุ่มที่กด)
  // ---------------------------------------------------------------------------
  Widget _buildBody() {
    if (_isLoading) {
      // ถ้าสถานะเป็นกำลังโหลดข้อมูล
      return const Center(
        child: CircularProgressIndicator(),
      ); // โชว์วงกลมหมุนๆ ตรงกลางจอ
    }

    if (_records.isEmpty) {
      // ถ้าโหลดข้อมูลเสร็จแล้ว แต่ในฐานข้อมูลไม่มีประวัติเลยแม้แต่ชิ้นเดียว
      return ListView(
        // สร้างจอเปล่าๆ ให้เลื่อนได้
        padding: const EdgeInsets.all(24),
        children: const [
          HistoryEmptyView(),
        ], // โชว์วิดเจ็ต "ยังไม่มีประวัติ" ที่สร้างไว้ในอีกไฟล์
      );
    }

    // 📌 5. คัดกรองข้อมูล: สร้างตู้คอนเทนเนอร์เปล่าๆ ไว้เตรียมรับข้อมูลที่ผ่านการกรองแล้ว
    List<HistoryRecordModel> displayList = [];

    if (_selectedFilterIndex == 0) {
      // ถ้ากดปุ่มที่ 0 (ทั้งหมด)
      displayList = _records; // โยนประวัติทุกอย่างใส่เข้าไปโชว์เลย ไม่ต้องกรอง
    } else if (_selectedFilterIndex == 1) {
      // ถ้ากดปุ่มที่ 1 (รอใส่น้ำหนัก)
      // ใช้คำสั่ง .where() เพื่อดึงมาเฉพาะรายการที่ค่า isPendingWeight เป็น true (คืออันที่รอใส่น้ำหนัก)
      displayList = _records.where((item) => item.isPendingWeight).toList();
    } else if (_selectedFilterIndex == 2) {
      // ถ้ากดปุ่มที่ 2 (ประวัติวัสดุ)
      // ใช้คำสั่ง .where() คัดมาเฉพาะรายการที่ไม่ค้างน้ำหนัก (เติมเครื่องหมาย ! แปลว่า Not หรือ ไม่)
      displayList = _records.where((item) => !item.isPendingWeight).toList();
    } else if (_selectedFilterIndex == 3) {
      // ถ้ากดปุ่มที่ 3 (รายได้)
      return _buildRevenueTab(); // 💡 พิเศษ! ให้เด้งไปเรียกฟังก์ชันวาดหน้าจอสรุปรายได้แทน
    }

    // เช็คดักไว้: ถ้าผู้ใช้กดเข้ามาหมวดหมู่นี้แล้วมันไม่มีข้อมูลเลย (เช่น ไม่มีของที่รอใส่น้ำหนักเลย)
    if (displayList.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Center(
            child: Text(
              'ไม่มีรายการในหมวดหมู่นี้',
              style: TextStyle(color: Colors.grey),
            ),
          ), // โชว์ข้อความว่าไม่มีของ
        ],
      );
    }

    // กรณีปกติ (มีข้อมูล): เอาข้อมูลที่กรองแล้ว (displayList) มาวนลูปวาดเป็นการ์ด
    return ListView.separated(
      padding: const EdgeInsets.all(20), // เว้นขอบทุกด้าน 20
      itemCount: displayList
          .length, // จำนวนการ์ดที่จะสร้าง (เท่ากับจำนวนข้อมูลที่กรองมา)
      separatorBuilder: (context, index) => const SizedBox(
        height: 14,
      ), // ตัวคั่นระหว่างการ์ด ให้ห่างกัน 14 พิกเซล
      itemBuilder: (context, index) {
        // เริ่มวาดการ์ดทีละใบ
        final record =
            displayList[index]; // ดึงข้อมูลประวัติใบที่กำลังจะวาดมาเก็บไว้

        return HistoryRecordCard(
          // เรียกใช้วิดเจ็ตการ์ด (จากไฟล์ history_screen_widgets)
          record: record, // ส่งข้อมูลประวัติให้การ์ด
          onTap: () {
            // ถ้าผู้ใช้เอานิ้วจิ้มที่การ์ดใบนี้
            // สั่งเปิดหน้า HistoryDetailScreen (หน้าโชว์รายละเอียด) พร้อมส่งข้อมูล record ไปด้วย
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryDetailScreen(record: record),
              ),
            );
          },
          onDelete: () =>
              _deleteRecord(record), // ส่งฟังก์ชันลบไปให้ปุ่มถังขยะในการ์ด
          onWeightConfirmed: (weight) => _confirmWeight(
            record,
            weight,
          ), // ส่งฟังก์ชันกดยืนยันน้ำหนักไปให้ช่องพิมพ์น้ำหนักในการ์ด
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 🌟 หน้าจอพิเศษ: หมวดหมู่ "รายได้" (มีกล่องสถิติ Dashboard ยอดเงินรวมด้านบน)
  // ---------------------------------------------------------------------------
  Widget _buildRevenueTab() {
    // 📌 ใช้ความสามารถของ Extension (ที่อยู่ในไฟล์โมเดล) ดึงยอดรวมจากประวัติทั้งหมด
    final totalRevenue =
        _records.totalEstimatedPrice; // รวมยอดเงินประเมินทั้งหมดที่มีในแอป
    final totalCo2 = _records.totalCo2Saved; // รวมคาร์บอนทั้งหมด
    final totalPoints = _records.totalPointsEarned; // รวมคะแนนทั้งหมด

    // กรองข้อมูล: ดึงมาเฉพาะรายการที่ "ขายได้เงิน" (คือยอดเงิน > 0) เพื่อเอามาโชว์เป็นประวัติการขายด้านล่าง
    final revenueList = _records
        .where((item) => item.estimatedPrice > 0)
        .toList();

    return ListView(
      // ใช้ ListView วาดจอที่เลื่อนขึ้นลงได้
      padding: const EdgeInsets.all(20), // ขอบ 20
      children: [
        // 💰 ชิ้นส่วนที่ 1: กล่อง Dashboard สีเขียวเข้ม (โชว์ยอดเงินรวม)
        Container(
          padding: const EdgeInsets.all(20), // ขอบด้านในกล่อง
          decoration: BoxDecoration(
            // ตกแต่งกล่อง
            color: AppColors.darkGreen, // ใช้สีพื้นหลังเป็นสีเขียวเข้มสุด
            borderRadius: BorderRadius.circular(24), // ลบมุมโค้ง 24
            boxShadow: [
              // ใส่เงาให้กล่องดูลอยๆ ขึ้นมา
              BoxShadow(
                color: AppColors.darkGreen.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            // เรียงข้อความในกล่องจากบนลงล่าง
            children: [
              const Text(
                'รายได้รวมทั้งหมด',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ), // ข้อความหัวข้อเล็กๆ สีขาวขุ่น
              const SizedBox(height: 8),

              // 🌟 โชว์ยอดเงินรวม! (ใช้ NumberFormatter เพื่อให้มีลูกน้ำหลักพัน)
              Text(
                '${NumberFormatter.money(totalRevenue)} ฿', // แสดงตัวเลขเงิน
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ), // ตัวเลขสีขาว ใหญ่สะใจ (36) หนาสุด
              ),
              const SizedBox(height: 16),
              const Divider(
                color: Colors.white24,
              ), // วาดเส้นขีดคั่นสีขาวขุ่นบางๆ
              const SizedBox(height: 12),

              Row(
                // แถวล่างของกล่อง แบ่งเป็นซ้าย(คาร์บอน) และ ขวา(คะแนน)
                mainAxisAlignment: MainAxisAlignment
                    .spaceAround, // ดันให้เว้นระยะห่างเท่าๆ กัน
                children: [
                  _buildDashboardStat(
                    Icons.eco_rounded,
                    '${NumberFormatter.co2(totalCo2)} กก.',
                  ), // เรียกฟังก์ชันสร้างไอคอนคาร์บอน
                  _buildDashboardStat(
                    Icons.star_rounded,
                    '$totalPoints คะแนน',
                  ), // เรียกฟังก์ชันสร้างไอคอนคะแนน
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24), // เว้นห่างจากกล่อง Dashboard ลงมา
        // ชิ้นส่วนที่ 2: ข้อความหัวข้อ "รายการที่ขายได้"
        const Text(
          'รายการที่ขายได้',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),

        // ชิ้นส่วนที่ 3: โชว์ลิสต์ประวัติการขายที่เคยได้เงิน
        if (revenueList.isEmpty) // ถ้าไม่เคยขายของได้เงินเลย
          const Center(
            child: Text(
              'ยังไม่มีรายการที่สร้างรายได้',
              style: TextStyle(color: Colors.grey),
            ),
          ) // โชว์ข้อความ
        else // ถ้าเคยมีของขายได้เงิน
          ...revenueList.map(
            (record) => Padding(
              // กระจาย (Spread) ข้อมูลในลิสต์ออกมาวาดเป็นการ์ดทีละใบ
              padding: const EdgeInsets.only(
                bottom: 14,
              ), // เว้นขอบล่างการ์ดแต่ละใบ
              child: HistoryRecordCard(
                // วาดการ์ดประวัติเหมือนหน้าปกติเป๊ะ
                record: record, // ข้อมูลการ์ด
                onTap: () {
                  // พอกดให้ไปหน้าจอรายละเอียด
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryDetailScreen(record: record),
                    ),
                  );
                },
                onDelete: () => _deleteRecord(record), // ปุ่มลบ
                onWeightConfirmed: (weight) => _confirmWeight(
                  record,
                  weight,
                ), // ปุ่มยืนยันน้ำหนัก (จริงๆ หน้าได้เงินแล้วจะไม่มีปุ่มนี้โชว์)
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 🌟 ฟังก์ชันตัวช่วย: วาดไอคอนและตัวหนังสือเล็กๆ ในกล่อง Dashboard
  // ---------------------------------------------------------------------------
  Widget _buildDashboardStat(IconData icon, String text) {
    return Row(
      // จัดแนวนอน (ไอคอนอยู่ซ้าย ข้อความอยู่ขวา)
      children: [
        Icon(icon, color: Colors.white70, size: 20), // วาดไอคอนสีขาวขุ่น
        const SizedBox(width: 6), // เว้นระยะ 6
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ), // วาดข้อความอธิบาย (เช่น 12 คะแนน)
      ],
    );
  }
}
