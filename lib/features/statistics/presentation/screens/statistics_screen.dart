import 'package:flutter/material.dart'; // นำเข้าเครื่องมือวาดหน้าจอ

import '../../../../core/constants/app_colors.dart'; // นำเข้าสี
import '../../../../features/history/data/models/history_record_model.dart'; // โครงสร้างข้อมูลประวัติ
import '../../../../features/history/data/repositories/history_repository.dart'; // ตัวเชื่อมต่อ Database
import '../../../../services/database/app_database.dart'; // ฐานข้อมูล SQLite
import '../widgets/statistics_screen_widgets.dart'; // นำเข้าไฟล์ Widgets ที่เราเพิ่งเขียนไปเมื่อกี้

// ===========================================================================
// หน้าจอหลัก (StatefulWidget: หน้าจอนี้สามารถเปลี่ยนแปลงข้อมูลสดๆ บนจอได้)
// ===========================================================================
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState(); // สร้างกล่องความจำ (State) ให้หน้านี้
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // ประกาศตัวแปร _historyRepository ไว้เชื่อมต่อฐานข้อมูล (late แปลว่าจะกำหนดค่าให้มันทีหลัง)
  late final HistoryRepository _historyRepository;

  // ตัวแปรเก็บข้อมูล
  List<HistoryRecordModel> _records =
      []; // ตัวแปรแบบ List (อาร์เรย์) เอาไว้เก็บประวัติการสแกนทุกชิ้น เริ่มต้นให้เป็นกล่องเปล่า []
  bool _isLoading =
      true; // ตัวเช็คว่า "กำลังโหลดอยู่ไหม?" เริ่มมาให้เป็น true (จริง) เพื่อให้จอหมุนๆ ก่อน

  // ===========================================================================
  // โซนคำนวณตัวเลข (ใช้คำสั่ง get เพื่อให้มันคิดเลขสดๆ ใหม่ทุกครั้งที่โดนเรียก)
  // ===========================================================================

  // นับจำนวนรายการทั้งหมด โดยดึงขนาด (.length) ของลิสต์ _records
  int get _totalRecords => _records.length;
  // รวมราคา โดยไปเรียกใช้ฟังก์ชัน totalEstimatedPrice (มีคนเขียนสูตรบวกเลขรอไว้ในโมเดลแล้ว)
  double get _totalEstimatedValue => _records.totalEstimatedPrice;
  // รวมปริมาณ CO2 ที่ลดได้
  double get _totalCo2Saved => _records.totalCo2Saved;
  // รวมคะแนนที่ได้
  int get _totalPoints => _records.totalPointsEarned;

  // ฟังก์ชันแยกหมวดหมู่สัดส่วนวัสดุ
  Map<String, int> get _materialDistribution {
    final result =
        <String, int>{}; // สร้างตัวแปร result เป็น Map ว่างๆ เอาไว้จดข้อมูล
    for (final record in _records) {
      // วนลูป (for) หยิบประวัติมาดูทีละชิ้น
      // ถ้าเจอชื่อวัสดุนี้ในตารางแล้ว ให้นำเลขเดิมมาบวก 1
      // แต่ถ้ายังไม่เคยเจอ (?? 0) ให้เริ่มนับที่ 0 แล้วบวก 1
      result[record.material] = (result[record.material] ?? 0) + 1;
    }
    return result; // ส่งตารางสรุปที่จดเสร็จแล้วออกไป
  }

  // ฟังก์ชันแยกกิจกรรมรายเดือน
  Map<String, int> get _monthlyActivity {
    final result = <String, int>{}; // สร้างตารางว่างไว้จด
    for (final record in _records) {
      // วนลูปเหมือนเดิม
      // ดึงเดือนออกมา ถ้าเป็นเลขตัวเดียว (เช่น เลข 5) ให้เติมเลข 0 ด้านหน้าด้วย (.padLeft(2, '0')) จะได้เป็น 05
      // แล้วเชื่อมข้อความด้วยเครื่องหมายทับ (/) และตามด้วยปี
      final month =
          '${record.createdAt.month.toString().padLeft(2, '0')}/${record.createdAt.year}';

      // นับว่าเดือนนี้มีทำไปกี่รายการ (หลักการบวกเลขเหมือนวัสดุด้านบน)
      result[month] = (result[month] ?? 0) + 1;
    }
    return result; // ส่งตารางสรุปออกไป
  }

  // ===========================================================================
  // โซนเริ่มต้นทำงาน (initState จะทำงานแค่ "ครั้งแรกครั้งเดียว" ตอนเข้าหน้านี้)
  // ===========================================================================
  @override
  void initState() {
    super.initState();
    // 1. เชื่อมต่อตัวคลังข้อมูล (_historyRepository) เข้ากับ SQLite ของแอปเรา
    _historyRepository = HistoryRepository(database: AppDatabase.instance);

    // 2. สั่งให้ไปโหลดประวัติมาแสดง (เรียกฟังก์ชันด้านล่าง)
    _loadStatistics();
  }

  // ฟังก์ชันไปคุยกับ SQLite เพื่อดึงข้อมูลประวัติทั้งหมด
  Future<void> _loadStatistics() async {
    // async แปลว่าฟังก์ชันนี้มีการ "รอ" เกิดขึ้น
    try {
      // ลองทำคำสั่งในนี้ดู ถ้าพลาดให้เด้งไปเข้าบล็อก catch
      // สั่งให้ _historyRepository ไปดึงประวัติมาทั้งหมด (await คือการรอจนกว่าจะดึงเสร็จ)
      final records = await _historyRepository.getAllHistory();

      // สำคัญมาก! โค้ดป้องกันแอปพัง
      // เช็คว่าผู้ใช้กดเปลี่ยนหน้าหนีไปหรือยัง ถ้าเปลี่ยนหน้าไปแล้ว (!mounted) ให้หยุดทำงาน (return) ทันที
      if (!mounted) return;

      // ถ้าหน้าจอยังเปิดอยู่ ให้สั่ง setState (คำสั่งอัปเดตหน้าจอ)
      setState(() {
        _records = records; // เอาข้อมูลประวัติที่ดึงมา ยัดใส่ตัวแปร _records
        _isLoading =
            false; // โหลดเสร็จแล้ว สั่งให้ตัวหมุนๆ (Loading) หายไป (เป็น false)
      });
    } catch (error) {
      // ถ้าดึงข้อมูลพลาด (เช่น ฐานข้อมูลพัง) จะหลุดมาตรงนี้
      debugPrint(
        'Failed to load statistics: $error',
      ); // พ่นแจ้งเตือน Error ลงใน Log สีแดงๆ ของโปรแกรมเมอร์

      if (!mounted) return; // เช็คป้องกันแอปพังอีกรอบ

      setState(() {
        _records = []; // ถ้าพัง ก็ให้ตั้งค่าเป็นหน้าเปล่าๆ ไปเลย
        _isLoading = false; // และต้องเอาตัวหมุนๆ ออกด้วย ไม่หน้าจอจะค้าง
      });
    }
  }

  // ===========================================================================
  // โซนวาดหน้าจอ (build จะทำงานทุกครั้งที่มีการ setState)
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // วิดเจ็ตโครงร่างหน้าจอ
      backgroundColor: AppColors.background, // ระบายสีพื้นหลังสุด
      // ส่วนที่ 1: แถบชื่อหน้าจอด้านบน (AppBar)
      appBar: AppBar(
        title: const Text(
          'สถิติ',
          style: TextStyle(fontWeight: FontWeight.w900),
        ), // ชื่อหน้า "สถิติ"
        backgroundColor: AppColors.background, // สีพื้นหลังแถบบน
        elevation: 0, // ปิดเงาให้มันเรียบแบนไปกับจอ
        actions: [
          // ปุ่มไอคอนมุมขวาบน (ปุ่มหมุนๆ รีเฟรช)
          IconButton(
            tooltip: 'รีเฟรช', // คำอธิบายเวลาเอาเมาส์ชี้
            onPressed:
                _loadStatistics, // เวลากดให้ไปเรียกฟังก์ชัน _loadStatistics ด้านบน
            icon: const Icon(Icons.refresh_rounded), // รูปไอคอน
          ),
        ],
      ),

      // ส่วนที่ 2: เนื้อหาหน้าจอ
      body: SafeArea(
        // พื้นที่ปลอดภัย (ป้องกันการวาดของไปทับติ่งกล้องมือถือ)
        // RefreshIndicator ทำให้ผู้ใช้ใช้นิ้วดึงหน้าจอลงมาเพื่อรีเฟรชข้อมูลได้
        child: RefreshIndicator(
          onRefresh: _loadStatistics, // เวลาดึงจอลงมา ให้เรียกฟังก์ชันนี้
          color: AppColors.primaryGreen, // สีของลูกศรโหลดตอนดึงจอ
          // โค้ดเช็คเงื่อนไข:
          // ถ้า _isLoading เป็นจริง (?) -> โชว์ตัวหมุนๆ กึ่งกลางจอ (CircularProgressIndicator)
          // ถ้าเป็นเท็จ (:) -> โชว์ลิสต์หน้าจอปกติ (ListView)
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20), // ขอบจอ 20 พิกเซลรอบด้าน
                  children: [
                    // --- ตรงนี้คือการเอาวิดเจ็ตจากไฟล์ widgets มาต่อกันเหมือนต่อเลโก้ ---

                    // เลโก้ชิ้นที่ 1: ตารางสรุป 4 กล่อง
                    StatisticsSummaryGrid(
                      totalRecords: _totalRecords, // โยนยอดรวมไปให้มันวาด
                      totalEstimatedValue: _totalEstimatedValue,
                      totalCo2Saved: _totalCo2Saved,
                      totalPoints: _totalPoints,
                    ),
                    const SizedBox(height: 24), // เว้นระยะห่างแนวตั้ง
                    // เลโก้ชิ้นที่ 2: สัดส่วนวัสดุ
                    StatisticsSectionCard(
                      // เรียกใช้กรอบการ์ดใหญ่
                      title: 'สัดส่วนวัสดุ',
                      icon: Icons.pie_chart_rounded, // ไอคอนวงกลม
                      // ถ้า _records ว่างเปล่า (?) โชว์ข้อความ "ยังไม่มีข้อมูล"
                      // ถ้ามีข้อมูล (:) โชว์วิดเจ็ตหลอดเปอร์เซ็นต์
                      child: _records.isEmpty
                          ? const StatisticsEmptyText('ยังไม่มีข้อมูลวัสดุ')
                          : StatisticsDistributionList(
                              data:
                                  _materialDistribution, // โยนตารางสรุปวัสดุไปให้
                              total:
                                  _totalRecords, // โยนจำนวนชิ้นทั้งหมดไปเพื่อเป็นฐานคำนวณเปอร์เซ็นต์หลอด
                            ),
                    ),
                    const SizedBox(height: 16),

                    // เลโก้ชิ้นที่ 3: กิจกรรมรายเดือน
                    StatisticsSectionCard(
                      title: 'กิจกรรมรายเดือน',
                      icon: Icons.bar_chart_rounded, // ไอคอนกราฟแท่ง
                      child: _records.isEmpty
                          ? const StatisticsEmptyText('ยังไม่มีกิจกรรมรายเดือน')
                          : StatisticsMonthlyActivityList(
                              data: _monthlyActivity, // โยนตารางสรุปเดือนไปให้
                            ),
                    ),
                    const SizedBox(height: 16),

                    // เลโก้ชิ้นที่ 4: กล่องสีเขียวเข้ม (ผลกระทบต่อสิ่งแวดล้อม)
                    StatisticsEnvironmentalSummary(
                      totalCo2Saved: _totalCo2Saved, // โยน CO2
                      totalPoints: _totalPoints, // โยนคะแนน
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
