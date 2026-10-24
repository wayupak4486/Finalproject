import 'package:flutter/material.dart'; 

import '../../../../app/router.dart'; // ดึงระบบจัดการเส้นทาง (เปลี่ยนหน้า)
import '../../../../core/constants/app_colors.dart'; 
import '../../../../features/history/data/models/history_record_model.dart'; 
import '../../../../features/history/data/repositories/history_repository.dart'; 
import '../../../../services/database/app_database.dart'; 
import '../widgets/home_screen_widgets.dart'; // ดึงชิ้นส่วน UI สำหรับหน้าโฮมโดยเฉพาะ

// ===========================================================================
// 📱 หน้าโฮมหลัก (HomeScreen)
// ===========================================================================
class HomeScreen extends StatefulWidget {
  // 📦 รับค่า historyLoader เข้ามา (ไม่บังคับใส่ มี ? ต่อท้าย)
  const HomeScreen({super.key, this.historyLoader}); 

  // 💡 เอาไว้ตอบอาจารย์: "ตัวนี้เอาไว้ใช้ตอนทำ Widget Test ครับอาจารย์ 
  // มันช่วยให้เรายัดข้อมูลจำลองเข้ามาเทสหน้าจอได้ โดยไม่ต้องไปยุ่งกับ SQLite ของจริงครับ"
  final Future<List<HistoryRecordModel>> Function()? historyLoader;

  @override
  State<HomeScreen> createState() => _HomeScreenState(); 
}

class _HomeScreenState extends State<HomeScreen> {
  // =========================================================================
  // 📦 โซนที่ 1: พจนานุกรมตัวแปร (Variables & Getters)
  // =========================================================================
  
  // ตัวจัดการ Database
  late final HistoryRepository _historyRepository; 

  // ถังเก็บประวัติ และสถานะการโหลด
  List<HistoryRecordModel> _records = []; 
  bool _isLoading = true; 

  // 🧮 Getters: ตัวแปรแบบ "คำนวณสด (Computed)"
  // มันจะไปดึง Extension (.total...) ที่เราเขียนไว้ใน history_record_model.dart มาคำนวณยอดรวม
  double get _totalEstimatedValue => _records.totalEstimatedPrice; 
  double get _totalCo2Saved => _records.totalCo2Saved; 
  int get _totalPoints => _records.totalPointsEarned; 

  // =========================================================================
  // ⚙️ โซนที่ 2: วงจรชีวิต (Lifecycle)
  // =========================================================================
  @override
  void initState() {
    super.initState();
    // สร้างตัวเชื่อม Database
    _historyRepository = HistoryRepository(database: AppDatabase.instance); 
    // โหลดข้อมูลขึ้นหน้าจอทันที
    _loadHistory(); 
  }

  // =========================================================================
  // 📡 โซนที่ 3: ฟังก์ชันดึงข้อมูล (Data Fetching)
  // =========================================================================
  Future<void> _loadHistory() async {
    try {
      // 💡 เงื่อนไขสุดฉลาด (?? operator): 
      // ถ้า widget.historyLoader ถูกส่งมาจากระบบ Test ให้เรียกใช้ข้อมูลจำลองนั้น (call)
      // แต่ถ้าไม่มี (เป็น null) ให้ไปดึงจาก SQLite ของจริงแทน (_historyRepository)
      final records = await (widget.historyLoader?.call() ?? _historyRepository.getAllHistory());

      if (!mounted) return; // ป้องกันแครชถ้าผู้ใช้ปิดหน้าจอหนี

      setState(() {
        _records = records; // อัปเดตข้อมูลลงถัง
        _isLoading = false; // ปิดสถานะกำลังโหลด
      });
    } catch (error) {
      debugPrint('Failed to load history: $error'); 
      if (!mounted) return;

      setState(() {
        _records = []; 
        _isLoading = false; 
      });
    }
  }

  // =========================================================================
  // 🚀 โซนที่ 4: ฟังก์ชันนำทาง (Navigation) เปลี่ยนหน้า
  // 💡 เอาไว้ตอบอาจารย์: "ทำไมต้องมี await หน้า _loadHistory() ด้วย?"
  // คำตอบ: "เพราะเวลาเรากระโดดไปหน้าสแกน หน้าโฮมจะรออยู่ (await) พอสแกนเสร็จกดย้อนกลับมา 
  // โค้ดบรรทัดถัดไปคือ _loadHistory() จะทำงานทันที ทำให้ยอดเงินบนแดชบอร์ดเด้งอัปเดตแบบ Real-time ครับ"
  // =========================================================================

  Future<void> _openScanScreen() async {
    await Navigator.pushNamed(context, AppRoutes.scan); // ไปหน้าสแกน (ใช้ชื่อ Route)
    await _loadHistory(); // กลับมาปุ๊บ อัปเดตข้อมูล!
  }

  Future<void> _openHistoryScreen() async {
    await Navigator.pushNamed(context, AppRoutes.history); 
    await _loadHistory(); 
  }

  Future<void> _openStatisticsScreen() async {
    await Navigator.pushNamed(context, AppRoutes.statistics); 
    await _loadHistory(); 
  }

  Future<void> _openPriceScreen() async {
    await Navigator.pushNamed(context, AppRoutes.prices); 
    await _loadHistory(); 
  }

  // =========================================================================
  // 🎨 โซนที่ 5: วาดหน้าจอ (Build UI)
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, 
      
      // 1. แถบด้านบนสุด (มีแค่ปุ่มตั้งค่าฟันเฟืองทางขวา)
      appBar: AppBar(
        backgroundColor: AppColors.background, 
        elevation: 0, // ปิดเงาใต้ AppBar ให้แบนเรียบไปกับพื้น
        title: const SizedBox.shrink(), // ไม่ใส่ข้อความหัวเรื่อง (SizedBox.shrink คือกล่องล่องหน)
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              tooltip: 'ตั้งค่า',
              // 🛠️ วิธีแก้โค้ด: ถ้าอยากเปลี่ยนปุ่มตั้งค่าให้ไปหน้าอื่น แก้ AppRoutes.settings เป็นชื่ออื่น
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings), 
              icon: const Icon(Icons.settings_rounded), 
              iconSize: 32,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      
      // 2. เนื้อหาหลัก
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory, // ดึงจอลงเพื่อโหลดข้อมูลใหม่
          
          child: ListView(
            // เว้นขอบจอ: ซ้าย 24, บน 8, ขวา 24, ล่าง 28
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28), 
            children: [
              
              // ชิ้นส่วนที่ 1: ข้อความทักทายตอนเปิดแอป (ดึงมาจากไฟล์ widget)
              const HomeAppIntro(), 
              const SizedBox(height: 22), 
              
              // ชิ้นส่วนที่ 2: การ์ดกดสแกนขยะใบใหญ่
              // ส่งฟังก์ชัน _openScanScreen ไปให้การ์ด
              HomeScanHeroCard(onTap: _openScanScreen), 
              const SizedBox(height: 28), 
              
              // ชิ้นส่วนที่ 3: หัวข้อ "สถิติภาพรวม"
              Text(
                'สถิติภาพรวม', 
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900, letterSpacing: -0.4, color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16), 
              
              // ชิ้นส่วนที่ 4: กล่องตารางแดชบอร์ด 4 ช่อง
              // โยนตัวแปร Getter ที่คำนวณไว้ด้านบน (เงินรวม, คาร์บอนรวม, แต้มรวม) เข้าไปแสดงผล
              HomeDashboardGrid(
                totalRecords: _records.length, // จำนวนครั้งที่สแกน
                totalEstimatedValue: _totalEstimatedValue, 
                totalCo2Saved: _totalCo2Saved, 
                totalPoints: _totalPoints, 
              ),
              const SizedBox(height: 30), 
              
              // ชิ้นส่วนที่ 5: ปุ่มรอง (ดูสถิติ)
              HomeSecondaryActionButton(
                label: 'ดูสถิติ', icon: Icons.bar_chart_rounded, onPressed: _openStatisticsScreen,
              ),
              const SizedBox(height: 14), 
              
              // ชิ้นส่วนที่ 6: ปุ่มรอง (ราคารับซื้อ)
              HomeSecondaryActionButton(
                label: 'ราคารับซื้อ', icon: Icons.price_change_rounded, onPressed: _openPriceScreen,
              ),
              const SizedBox(height: 34), 
              
              // ชิ้นส่วนที่ 7: หัวข้อ "ประวัติล่าสุด" พร้อมปุ่ม "ดูทั้งหมด"
              HomeSectionHeader(
                title: 'ประวัติล่าสุด', actionLabel: 'ดูทั้งหมด', onActionTap: _openHistoryScreen,
              ),
              const SizedBox(height: 14), 
              
              // ชิ้นส่วนที่ 8: โซนแสดงประวัติล่าสุด (โชว์แค่อันเดียว)
              // มีการเช็ค 3 เงื่อนไข (If-Else)
              if (_isLoading)
                // เงื่อนไข 1: กำลังโหลด โชว์การ์ดโหลดจำลอง
                const HomeLoadingHistoryCard() 
              else if (_records.isEmpty)
                // เงื่อนไข 2: โหลดเสร็จแต่ไม่มีข้อมูล โชว์หน้าว่าง
                const HomeEmptyRecentHistory() 
              else
                // เงื่อนไข 3: มีข้อมูล ให้ดึงข้อมูลตำแหน่งที่ 0 (ใหม่สุด) มาโชว์ 1 ใบ
                // 🛠️ วิธีแก้โค้ด: ถ้าอยากโชว์ใบที่ 2 ให้แก้เป็น _records[1]
                HomeRecentHistoryCard(record: _records.first), 
            ],
          ),
        ),
      ),
    );
  }
}