import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/material_catalog.dart';
import '../../../../services/database/app_database.dart';
import '../../../../services/price_source/wongpanit_price_service.dart';
import '../../data/models/material_price_model.dart';
import '../../data/repositories/material_price_repository.dart';
import '../../data/services/price_update_service.dart';
import 'price_management_screen.dart';
import '../widgets/price_screen_widgets.dart';

// ===========================================================================
// หน้าจอหลัก (StatefulWidget) : ใช้ Stateful เพราะหน้าจอสามารถเปลี่ยนสถานะได้
// เช่น จาก "กำลังโหลด" เป็น "โหลดเสร็จแล้ว" หรือ "เกิด Error"
// ===========================================================================
class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  // 💡 โซนตัวแปรที่ติดต่อกับระบบหลังบ้าน
  late final MaterialPriceRepository _priceRepository; // ตัวคุยกับ Database
  late final PriceUpdateService _priceUpdateService; // ตัวดูดข้อมูลเว็บ

  // 💡 โซนสถานะ (State) ของหน้าจอ (ค่าพวกนี้เปลี่ยนปุ๊บ หน้าจอเปลี่ยนปั๊บ)
  List<MaterialPriceModel> _prices = []; // กล่องเก็บข้อมูลราคาทั้งหมด
  bool _isLoading = true; // สวิตช์: เปิดหน้ามาครั้งแรกให้หมุนโหลดก่อน
  bool _isUpdating = false; // สวิตช์: ปุ่ม "อัปเดตราคาจากเว็บ" กำลังทำงานไหม?
  String? _errorMessage; // กล่องเก็บข้อความ Error สีแดง (เป็น null ได้)

  // 💡 ฟังก์ชันประเภท Getter (คำนวณสด) หาเวลา "อัปเดตล่าสุด" 
  // โดยหยิบทุกรายการมาเทียบเวลา (isAfter) แล้วเอาอันที่ใหม่ที่สุดมาแสดง
  DateTime? get _lastUpdated {
    if (_prices.isEmpty) return null; // ถ้าไม่มีข้อมูลเลย คืนค่าว่าง
    return _prices
        .map((price) => price.updatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // 💡 ฟังก์ชันวงจรชีวิต (Lifecycle): ทำงานครั้งแรกครั้งเดียวตอนเปิดหน้านี้
  @override
  void initState() {
    super.initState();
    // 1. เตรียมเครื่องมือเชื่อมต่อ Database (SQLite)
    _priceRepository = MaterialPriceRepository(database: AppDatabase.instance);
    _priceUpdateService = PriceUpdateService(priceRepository: _priceRepository);

    // 2. สั่งโหลดราคาจากเครื่องมาแสดงบนจอทันที
    _loadPrices();
  }

  // ===========================================================================
  // ระบบหลังบ้าน: ฟังก์ชันจัดการข้อมูล
  // ===========================================================================

  /// โหลดรายการราคาจาก SQLite เพื่อแสดงบนหน้านี้
  Future<void> _loadPrices() async {
    // ใช้ try-catch ดักจับ Error กันแอปเด้งหลุด
    try {
      // await = รอให้โหลดจาก SQLite เสร็จก่อนค่อยทำบรรทัดถัดไป
      final prices = await _priceRepository.getAllPrices();

      // 💡 [จุดสำคัญ] if (!mounted) return;
      // ป้องกันแอปพัง กรณีผู้ใช้เน็ตช้าแล้วกดออกหน้านี้ไปก่อนที่ข้อมูลจะโหลดเสร็จ
      if (!mounted) return;

      // setState แจ้ง Flutter ให้วาดหน้าจอใหม่ด้วยข้อมูลชุดใหม่
      setState(() {
        _prices = prices; // เอาข้อมูลยัดใส่ตัวแปร
        _isLoading = false; // โหลดเสร็จแล้ว สั่งปิดตัวหมุนๆ ตรงกลางจอ
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // ถ้าเกิด Error ก็ต้องเลิกหมุน ไม่งั้นค้าง
      });
    }
  }

  /// เรียก service ดึงราคาเว็บ แล้วโหลดข้อมูล SQLite มาแสดงอีกครั้ง
  Future<void> _updatePrices() async {
    // 1. เปลี่ยนสถานะปุ่มเป็นกำลังโหลด และล้างข้อความ Error เก่าทิ้ง
    setState(() {
      _isUpdating = true; // ให้ปุ่มหมุนๆ
      _errorMessage = null; 
    });

    try {
      // 2. สั่งดูดข้อมูลจากเว็บ (ไปเรียกเว็บ Wongpanit)
      final result = await _priceUpdateService.updateFromWeb();
      // 3. ดูดเสร็จ มันเซฟลง DB แล้ว เราก็สั่งดึงจาก DB มาโชว์บนจอใหม่
      await _loadPrices();

      if (!mounted) return;

      // 4. โชว์ข้อความด้านล่างจอ (SnackBar) ว่าอัปเดตสำเร็จ
      // 💡 แก้ข้อความแจ้งเตือนสำเร็จตรงนี้
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'อัปเดตราคาแล้ว ${result.updatedCount}/${result.totalLabels} รายการจากเว็บ',
          ),
        ),
      );
    } on PriceFetchException catch (error) {
      // กรณีเชื่อมต่อเว็บไม่ได้ หรือเว็บมีการเปลี่ยนหน้าตา
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message; // โชว์ข้อความสีแดง
      });
    } catch (error) {
      // กรณี Error พังเรื่องอื่นๆ นอกเหนือจากเว็บ
      if (!mounted) return;
      setState(() {
        // 💡 แก้ข้อความ Error ตรงนี้
        _errorMessage = 'เกิดข้อผิดพลาดขณะอัปเดตราคา'; 
      });
    } finally {
      // finally = ไม่ว่าจะสำเร็จหรือพัง โค้ดตรงนี้ต้องทำงานเสมอ!
      if (mounted) {
        setState(() {
          _isUpdating = false; // เลิกหมุนในปุ่ม ให้ปุ่มกลับมาเป็นปกติ
        });
      }
    }
  }

  /// เปิดหน้าจัดการราคาแบบพิมพ์เอง
  Future<void> _openPriceManagement() async {
    // 💡 การใช้ Navigator.push แบบใส่ await
    // ระบบจะพาไปหน้าจัดการ และ "หยุดรอ" ตรงนี้จนกว่าผู้ใช้จะกดย้อนกลับมา
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const PriceManagementScreen()),
    );
    // พอกลับมาถึงหน้านี้ ให้ดึงข้อมูลจาก DB มาโชว์ใหม่เผื่อว่าผู้ใช้แอบพิมพ์แก้ราคา
    await _loadPrices();
  }

  // ===========================================================================
  // โครงสร้างหน้าจอ (UI) ที่นำ Widget จากไฟล์ย่อยมาประกอบร่าง
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // 💡 แก้สีพื้นหลังแอป
      
      // แถบด้านบนจอ (AppBar)
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0, // 0 = ไม่มีเงาใต้แถบ
        title: Text(
          'ราคารับซื้อ', // 💡 แก้ข้อความแถบด้านบน
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900, // ฟอนต์หนาสุด
            fontSize: PriceStyle.appBarTitleFontSize, // ขนาดฟอนต์
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      
      // ส่วนเนื้อหา (Body)
      body: SafeArea(
        // RefreshIndicator = เอานิ้วดึงจอลงมาเพื่อรีเฟรช (จะเรียกฟังก์ชัน _loadPrices)
        child: RefreshIndicator(
          onRefresh: _loadPrices, 
          // เช็ค: ถ้า _isLoading เป็น true โชว์วงกลมหมุนๆ : ถ้า false โชว์ข้อมูล ListView
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), // ระยะขอบ ซ้าย-บน-ขวา-ล่าง
                  children: [
                    // --- วางชิ้นส่วน Widget เรียงลงมา (เลโก้) ---
                    const PriceHeaderCard(), // กล่องอธิบายด้านบน
                    const SizedBox(height: 18), // เว้นระยะ

                    PriceLastUpdatedRow(lastUpdated: _lastUpdated), // แถวบอกเวลาล่าสุด
                    const SizedBox(height: 14),

                    // ปุ่ม: อัปเดตราคาจากเว็บ
                    PriceUpdateButton(
                      isUpdating: _isUpdating,
                      onPressed: _updatePrices, // พอกดปุ่ม ให้เรียกฟังก์ชันดึงเว็บ
                    ),
                    const SizedBox(height: 12),
                    
                    // ปุ่ม: จัดการราคา
                    FilledButton.icon(
                      onPressed: _openPriceManagement, // พอกดปุ่ม ให้เปิดหน้าจัดการ
                      icon: const Icon(Icons.edit_rounded, size: 28),
                      label: const Text('จัดการราคา'), // 💡 แก้คำบนปุ่มตรงนี้
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen, // สีปุ่ม
                        foregroundColor: Colors.white, // สีตัวหนังสือในปุ่ม
                        minimumSize: Size.fromHeight(PriceStyle.updateButtonHeight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22), // ความโค้งปุ่ม
                        ),
                        textStyle: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              fontSize: PriceStyle.updateButtonFontSize,
                            ),
                      ),
                    ),

                    // ถ้ามี Error จากการดึงเว็บ (_errorMessage ไม่เป็น null) ให้วาดกล่องสีแดงโชว์
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      PriceErrorBanner(message: _errorMessage!), 
                    ],

                    const SizedBox(height: 26),

                    // --- วงลูปสร้างการ์ดราคาวัสดุ ---
                    // ดึงข้อมูล _prices มาคัดกรอง (.where) เอาเฉพาะตัวที่ตั้งค่าว่าขายได้ (isSellable)
                    for (final price in _prices.where(
                      (price) => MaterialCatalog.lookup(price.label).isSellable,
                    )) ...[
                      PriceCard(price: price), // สร้างการ์ดทีละใบ
                      const SizedBox(height: 14), // ระยะห่างระหว่างการ์ด
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}