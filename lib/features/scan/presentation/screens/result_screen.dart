//  ต้นเหตุ: ช่องพิมพ์ (TextField) จำตัวเลขของมันเองไว้ใน _priceController
//            มันไม่ได้ผูกกับตัวแปร _pricePerKg อัตโนมัติ
//            ถ้าเราไม่สั่ง "เปลี่ยนข้อความในช่อง" เอง ช่องจะค้างเลขเดิมตลอด
//
//  วิธีแก้ (ง่ายสุด): สร้างฟังก์ชันเดียวชื่อ _syncPriceField()
//            หน้าที่ของมันมีอย่างเดียวคือ "เอาราคาปัจจุบันไปใส่ในช่องราคา"
//            แล้วเรียกใช้ใน 3 จุด จุดละ 1 บรรทัด
//
//  วิธีหาจุดที่แก้: กด Ctrl+F ค้นคำว่า  🔧  จะเจอทั้งหมด 5 ที่ คือ
//    🔧 A = ตัวฟังก์ชัน _syncPriceField() (ประกาศไว้ใช้)
//    🔧 B = เรียกใช้ตอนเปิดหน้าครั้งแรก (อยู่ใน build)
//    🔧 C = เรียกใช้ตอนโหลดราคาจาก DB เสร็จ (อยู่ใน _loadLivePrices)
//    🔧 D = เรียกใช้ตอนเปลี่ยนชนิดขยะ (อยู่ใน _pickMaterial)
//    🔧 E = ลบบล็อกเติมราคาเก่าทิ้ง (อยู่ใน _buildPriceCard) ← ตัวต้นเหตุของบั๊ก
//

import 'package:flutter/material.dart'; // เครื่องมือสร้างหน้าจอ

import '../../../../app/router.dart'; // ระบบเปลี่ยนหน้า
import '../../../../core/constants/app_constants.dart'; // ค่าคงที่ระบบ
import '../../../../core/constants/material_catalog.dart'; // ข้อมูลขยะ
import '../../../../core/utils/calculation_utils.dart'; // เครื่องคิดเลขคำนวณราคาและคาร์บอน
import '../../../../core/utils/number_formatter.dart'; // ตัวเติมลูกน้ำให้ตัวเลข
import '../../../../features/history/data/models/history_record_model.dart'; // โครงสร้างข้อมูลประวัติเพื่อเซฟลง DB
import '../../../../features/history/data/repositories/history_repository.dart'; // ตัวคุยกับ DB หมวดประวัติ
import '../../../../features/prices/data/repositories/material_price_repository.dart'; // ตัวคุยกับ DB หมวดราคา
import '../../../../services/database/app_database.dart'; // ตัวเชื่อมต่อ SQLite
import '../../data/models/scan_result_args.dart'; // โครงสร้างข้อมูลที่รับส่งมา
import '../widgets/result_screen_widgets.dart'; // ชิ้นส่วน UI

// ===========================================================================
// หน้าสรุปผลแบบละเอียด (Stateful เพราะต้องพิมพ์น้ำหนักแล้วราคาต้องเด้งอัปเดตตามสดๆ)
// ===========================================================================
class ResultScreen extends StatefulWidget {
  // StatefulWidget = วิดเจ็ตที่ "มีข้อมูลเปลี่ยนแปลงได้" (ต่างจาก Stateless ที่นิ่งตายตัว)
  const ResultScreen({super.key}); // คอนสตรัคเตอร์

  @override
  State<ResultScreen> createState() => _ResultScreenState(); // สร้าง State (ที่เก็บข้อมูลที่เปลี่ยนแปลงได้ของหน้านี้)
}

class _ResultScreenState extends State<ResultScreen> {
  // 1. Controller สำหรับดูดข้อความจากช่องพิมพ์
  // (Controller = ตัวจับ/ตัวสั่งข้อความในช่องพิมพ์ ใช้ทั้ง "อ่าน" และ "เขียนทับ" ข้อความได้)
  final TextEditingController _weightController =
      TextEditingController(); // ดูดช่องน้ำหนัก
  final TextEditingController _noteController =
      TextEditingController(); // ดูดช่องหมายเหตุ
  // 💡 เพิ่ม Controller สำหรับช่องกรอกราคา เพื่อให้ผู้ใช้พิมพ์แก้ราคาได้
  // (ตัวนี้แหละที่เราจะสั่งเปลี่ยนข้อความผ่าน _syncPriceField)
  final TextEditingController _priceController = TextEditingController();

  // 2. ตัวแปลสำหรับคุยกับ Database
  late final HistoryRepository _historyRepository; // เอาไว้เซฟประวัติ
  late final MaterialPriceRepository
  _priceRepository; // เอาไว้ดึงราคาอัปเดตล่าสุด
  // (late = ประกาศไว้ก่อน แล้วค่อยกำหนดค่าใน initState ด้านล่าง)

  // 3. ตัวแปรเก็บข้อมูลหน้าจอ
  ScanResultArgs? _args; // ข้อมูลที่รับข้ามหน้าจอมา (รูป, ผล AI)
  String? _selectedLabel; // ชื่อขยะที่ผู้ใช้อาจจะแก้ (ถ้ายังไม่แก้ จะเป็น null)
  Map<String, double> _livePrices = {}; // ตารางเก็บราคาล่าสุด (ดึงจาก DB)
  double _weightKg = 0; // ตัวแปรเก็บน้ำหนักที่ผู้ใช้พิมพ์ (เริ่มต้นเป็น 0)

  // เก็บราคาที่ผู้ใช้พิมพ์ใน TextEditingController สำหรับรายการปัจจุบัน
  // ค่านี้ใช้คำนวณรายการนี้เท่านั้น ไม่ได้แก้ราคามาตรฐานใน SQLite
  double? _customPricePerKg;

  // ===========================================================================
  // 🧠 โซนเครื่องคิดเลข (ดึงค่าจากตัวแปรมาคำนวณสดๆ)
  // ใช้ get เพื่อให้มันคำนวณใหม่ทุกครั้งที่มีการดึงไปใช้ หน้าจอจะได้ไม่ค้าง
  // ===========================================================================

  // ดึงข้อมูลขยะปัจจุบัน (ถ้าแก้ชื่อขยะ ให้ดึงชื่อใหม่, ถ้าไม่ได้แก้ ดึงชื่อที่ AI ทาย)
  MaterialInfo get _materialInfo =>
      MaterialCatalog.lookup(_selectedLabel ?? _args!.result.label);
  // (?? แปลว่า "ถ้าตัวซ้ายเป็น null ให้ใช้ตัวขวาแทน")

  // เช็คว่าขยะชิ้นนี้ขายได้ไหม
  bool get _isSellable => _materialInfo.isSellable;

  // ลำดับเลือกราคา: ค่าที่ผู้ใช้แก้ในหน้านี้ → ราคา SQLite ตาม label → ราคาเริ่มต้น catalog
  // ถ้าวัสดุขายไม่ได้ จะใช้ราคา 0
  double get _pricePerKg => _isSellable
      ? (_customPricePerKg ??
            _livePrices[_selectedLabel ?? _args!.result.label] ??
            _materialInfo.pricePerKg)
      : 0;

  // เช็คว่า AI ทายมาแบบมั่นใจต่ำไหม
  bool get _isLowConfidence =>
      _args!.result.confidence < AppConstants.lowConfidenceThreshold;

  // คำนวณราคาประเมิน (เรียกใช้สูตร: น้ำหนัก x ราคาต่อกก.)
  double get _estimatedPrice => CalculationUtils.calculateEstimatedPrice(
    weightKg: _weightKg,
    pricePerKg: _pricePerKg,
  );

  // คำนวณคาร์บอนที่ลดได้ (เรียกใช้สูตร: น้ำหนัก x ค่าคงที่ CO2 ของขยะชนิดนั้น)
  double get _co2Saved => CalculationUtils.calculateCo2Saved(
    weightKg: _weightKg,
    co2Factor: _materialInfo.co2FactorPerKg,
  );

  // คำนวณคะแนนที่ได้ (แปลงจากปริมาณคาร์บอนที่ลดได้)
  int get _points => CalculationUtils.calculatePoints(_co2Saved);

  // ===========================================================================
  // 🔧 A) [ฟังก์ชันใหม่ ตัวเอกของการแก้บั๊ก] _syncPriceField
  // หน้าที่: "เอาราคาปัจจุบัน (_pricePerKg) ไปเขียนใส่ในช่องราคา"
  // ใครอยากให้ช่องราคาเปลี่ยนเลข ก็แค่เรียก _syncPriceField(); บรรทัดเดียว
  // ===========================================================================
  void _syncPriceField() {
    // _priceController.text = ข้อความในช่องราคา (เขียนทับได้)
    // _pricePerKg           = ราคาปัจจุบันที่คำนวณจากโซนเครื่องคิดเลขด้านบน
    // .toStringAsFixed(2)   = แปลงตัวเลขเป็นข้อความ ทศนิยม 2 ตำแหน่ง (67 -> "67.00")
    _priceController.text = _pricePerKg.toStringAsFixed(2);
  }

  // ===========================================================================
  // โซนเริ่มต้นทำงาน (ทำครั้งเดียวตอนเปิดหน้า)
  // ===========================================================================
  @override
  void initState() {
    super.initState(); // เรียกงานเริ่มต้นของ Flutter ก่อนเสมอ (ห้ามลืม)
    // เชื่อมต่อ DB
    _historyRepository = HistoryRepository(database: AppDatabase.instance);
    _priceRepository = MaterialPriceRepository(database: AppDatabase.instance);

    // สั่งให้ไปโหลดราคาขยะล่าสุดจาก DB มาเตรียมไว้
    // (โหลดแบบรอได้ จึงใช้เวลาแป๊บนึง หน้าจอจะวาดไปก่อน แล้วค่อยอัปเดตตอนโหลดเสร็จ)
    _loadLivePrices();
  }

  // ===========================================================================
  // โซนทำลายล้าง (ทำตอนปิดหน้านี้ทิ้ง)
  // ===========================================================================
  @override
  void dispose() {
    // ต้องทำลาย Controller เพื่อคืน RAM ให้มือถือ ป้องกันเครื่องค้าง
    _weightController.dispose();
    _noteController.dispose();
    _priceController.dispose(); //  ทำลาย Controller ราคาเพื่อคืน RAM
    super.dispose(); // เรียกงานทำลายของ Flutter ปิดท้าย
  }

  /// โหลดราคา SQLite ตาม label เพื่อให้การประเมินใช้ราคาล่าสุดที่บันทึกไว้
  Future<void> _loadLivePrices() async {
    try {
      // await รอ Repository อ่านข้อมูลจาก SQLite และจัดเป็น map ตาม label
      final prices = await _priceRepository.getPricesByLabel();
      if (!mounted) return; // เช็คว่าแอปยังไม่โดนปิดหนี
      setState(() {
        // setState อัปเดตข้อมูลราคาและทำให้หน้าจอคำนวณ/แสดงผลใหม่
        _livePrices = prices;

        // 🔧 C) [แก้ตรงนี้] ทันทีที่ราคาจาก DB มาถึง ให้อัปเดตเลขในช่องราคา
        // เงื่อนไข: ทำเฉพาะตอนที่ผู้ใช้ "ยังไม่ได้พิมพ์แก้ราคาเอง" (_customPricePerKg เป็น null)
        // ถ้าผู้ใช้พิมพ์ไปแล้ว ห้ามไปทับเลขที่เขาพิมพ์
        // ⚠️ บรรทัด _livePrices = prices ต้องอยู่ "ก่อน" บรรทัดนี้เสมอ
        //    เพราะ _syncPriceField จะอ่านราคาจาก _livePrices ที่เพิ่งอัปเดต
        if (_customPricePerKg == null) {
          _syncPriceField(); // เติมราคาจริงจาก DB ลงช่อง
        }
      });
    } catch (error) {
      debugPrint(
        'Failed to load live prices: $error',
      ); // พ่น log ลงหลังบ้านถ้ามีปัญหา
    }
  }

  // ฟังก์ชันเปิดแผ่นสไลด์ให้ผู้ใช้เลือกเปลี่ยนชนิดขยะ
  Future<void> _pickMaterial() async {
    final selected = await showModalBottomSheet<String>(
      // เรียก BottomSheet (แผ่นที่สไลด์ขึ้นมาจากข้างล่าง) แล้วรอผู้ใช้เลือก
      context: context,
      isScrollControlled: true, // ยอมให้แผ่นยาวขึ้นมาได้เยอะๆ
      showDragHandle: true, // โชว์ขีดตรงกลางแผ่นให้ดึงลงปิดได้
      builder: (context) => MaterialPickerSheet(
        // เรียกใช้วิดเจ็ตที่เราสร้างไว้ในไฟล์ widgets
        selectedLabel:
            _selectedLabel ?? _args!.result.label, // ส่งชื่อปัจจุบันไป
        aiLabel: _args!.result.label, // ส่งชื่อดั้งเดิมไป
      ),
    );

    if (selected == null)
      return; // ถ้าไม่ได้เลือกอะไร ปิดแผ่นไปเฉยๆ ให้หยุดทำงาน

    setState(() {
      // ถ้าเลือกขยะใหม่ ให้บันทึกและวาดหน้าจอใหม่ (ราคา/คาร์บอน จะเด้งเปลี่ยนทันที)
      _selectedLabel = selected; // จำชื่อขยะใหม่ที่ผู้ใช้เลือก

      // 🔧 D) [แก้ตรงนี้] เปลี่ยนชนิดขยะแล้ว ราคาที่เคยพิมพ์แก้ไว้เป็นของวัสดุตัวเก่า ต้องทิ้ง
      // แล้วเติมราคาของวัสดุตัวใหม่ลงช่อง
      // ⚠️ ลำดับสำคัญ 3 บรรทัด: (1) ตั้งชื่อใหม่ (2) ล้างราคาที่แก้ (3) เติมช่อง
      //    ถ้าสลับลำดับ ช่องจะได้ราคาของวัสดุตัวเก่า
      _customPricePerKg = null; // ล้างราคาที่ผู้ใช้เคยพิมพ์แก้ไว้
      _syncPriceField(); // เติมราคาของวัสดุใหม่ลงช่อง
    });
  }

  // ฟังก์ชันบันทึกข้อมูลทั้งหมดลงฐานข้อมูล
  Future<void> _saveRecord() async {
    final args = _args; // ดึงข้อมูล
    if (args == null) {
      // โค้ดดักจับกันบั๊ก
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบพาธรูปภาพ กรุณาสแกนใหม่อีกครั้ง')),
      );
      return; // จบการทำงานของฟังก์ชันทันที
    }

    // สร้างกล่องบรรจุข้อมูล (Model) 1 ชุด เพื่อเตรียมโยนลง Database
    final record = HistoryRecordModel(
      // 🔧 [แก้ตรงนี้] เดิมคือ  imagePath: args.imagePath,
      // args.imagePath ตอนนี้เป็น String? (อาจเป็น null ถ้าผู้ใช้เลือกวัสดุเองไม่ได้ถ่ายรูป)
      // แต่ตาราง history ใน SQLite ห้ามเก็บ null (image_path TEXT NOT NULL)
      // ?? '' แปลว่า "ถ้าเป็น null ให้ใช้ข้อความว่างแทน" ซึ่งเก็บลง DB ได้
      // ตอนแสดงผล ไฟล์ที่ชื่อว่างจะไม่มีอยู่จริง แอปเลยโชว์ไอคอนรูปภาพแทนให้อัตโนมัติ
      imagePath: args.imagePath ?? '', // พิกัดรูป (ไม่มีรูป = ข้อความว่าง)
      material: _materialInfo.displayName, // ชื่อวัสดุ
      category: _materialInfo.category, // หมวดหมู่
      confidence: args.result.confidence * 100, // ความมั่นใจ AI
      weight: _weightKg, // น้ำหนักที่พิมพ์
      pricePerKg: _pricePerKg, // ราคา (จะเป็นราคาที่ผู้ใช้แก้ ถ้ามีการแก้)
      estimatedPrice: _estimatedPrice, // ยอดรวม
      co2Saved: _co2Saved, // คาร์บอน
      co2FactorPerKg: _materialInfo
          .co2FactorPerKg, // ค่าคงที่คาร์บอน (เก็บเผื่อผู้ใช้มาใส่น้ำหนักทีหลัง)
      pointsEarned: _points, // คะแนน
      // เช็คว่าถ้าช่องหมายเหตุพิมพ์แต่ช่องว่าง ให้เก็บเป็น null แต่ถ้ามีตัวหนังสือให้ตัดช่องว่างหัวท้าย (.trim()) แล้วเซฟ
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: DateTime.now(), // เวลาปัจจุบัน
    );

    await _historyRepository.insertHistory(record); // โยนกล่องลง Database

    if (!mounted) return; // เช็คกันบั๊ก

    ScaffoldMessenger.of(context).showSnackBar(
      // โชว์แถบสำเร็จ
      const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
    );

    // ปิดหน้านี้ทิ้งทั้งหมด แล้วเด้งกลับไปที่หน้า "ประวัติ" (history)
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.history,
      (route) => route.isFirst,
    );
  }

  // ===========================================================================
  // 🎨 โซนวาดหน้าจอหลัก
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    // โค้ดรับข้อมูล: ??= หมายความว่า ถ้ารับข้อมูลมาแล้วให้จำไว้ ไม่ต้องรับใหม่ตอนหน้าจอกะพริบรีเฟรช
    _args ??= ModalRoute.of(context)?.settings.arguments as ScanResultArgs?;
    final args = _args; // ก๊อปมาใส่ตัวแปรสั้นๆ เพื่อเช็ค null ง่ายขึ้น

    // ถ้าบังเอิญไม่มีข้อมูลส่งมา (เช่น แอบเข้าหน้านี้ด้วยทางลัด) ให้โชว์จอเปล่าๆ ไม่แครช
    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ผลลัพธ์และการประเมิน')),
        body: const Center(
          child: Text('ไม่พบข้อมูลการสแกน กรุณาสแกนใหม่อีกครั้ง'),
        ),
      );
    }

    // กำหนดชื่อขยะเริ่มต้นให้เท่ากับที่ AI ทายมา
    // 🔧 B) [แก้ตรงนี้] เดิมบรรทัดนี้คือ  _selectedLabel ??= args.result.label;
    // เปลี่ยนเป็น if เพื่อให้ "ครั้งแรกครั้งเดียว" เติมราคาเริ่มต้นลงช่องด้วย
    // เงื่อนไข _selectedLabel == null จะเป็นจริงเฉพาะตอนวาดหน้าจอครั้งแรกเท่านั้น
    // (รอบถัดไป _selectedLabel มีค่าแล้ว จะข้ามบล็อกนี้ ไม่ไปทับเลขที่ผู้ใช้พิมพ์)
    // ทำไมต้องมี: เพราะเราลบบล็อกเติมราคาเก่าใน _buildPriceCard ทิ้ง (จุด E)
    //            ถ้าไม่เติมตรงนี้ ช่องจะว่างจนกว่า DB จะโหลดเสร็จ (หรือว่างตลอดถ้าโหลดพัง)
    if (_selectedLabel == null) {
      _selectedLabel =
          args.result.label; // ตั้งชื่อขยะเริ่มต้นเท่ากับที่ AI ทาย
      _syncPriceField(); // เติมราคาเริ่มต้น (ราคาแคตตาล็อก) ลงช่อง
    }
    final materialInfo = _materialInfo; // ดึงข้อมูลขยะปัจจุบันมาเตรียมวาด

    return Scaffold(
      appBar: AppBar(title: const Text('ผลลัพธ์และการประเมิน')), // แถบชื่อ
      body: SafeArea(
        // พื้นที่ปลอดภัย (กันเนื้อหาโดนรอยบากหน้าจอ/แถบระบบบัง)
        child: ListView(
          // ใช้ ListView เพื่อให้ไถจอขึ้นลงได้
          padding: const EdgeInsets.all(20), // เว้นขอบจอรอบทิศ 20
          children: [
            ResultCapturedImage(imagePath: args.imagePath), // วาดรูปภาพ
            const SizedBox(height: 16), // เว้นระยะห่างแนวตั้ง 16

            _buildAiAnalysisCard(
              args: args,
              materialInfo: materialInfo,
            ), // การ์ดที่ 1: ผลวิเคราะห์ (กดแก้ขยะได้)
            // ถ้าขยะนี้ขายได้ ถึงจะยอมวาดการ์ด น้ำหนัก, ราคา, สิ่งแวดล้อม
            if (_isSellable) ...[
              const SizedBox(height: 16),
              _buildWeightCard(), // การ์ดที่ 2: ช่องกรอกน้ำหนัก
              const SizedBox(height: 16),
              _buildPriceCard(), // การ์ดที่ 3: สรุปราคา
              const SizedBox(height: 16),
              _buildEnvironmentCard(), // การ์ดที่ 4: สรุปสิ่งแวดล้อม
            ],

            const SizedBox(height: 16),
            _buildTipsCard(materialInfo), // การ์ดที่ 5: เคล็ดลับแยกขยะ
            const SizedBox(height: 16),
            _buildNoteCard(), // การ์ดที่ 6: ช่องกรอกหมายเหตุ
            const SizedBox(height: 20),

            _buildSaveButton(), // ปุ่มล่างสุด
          ],
        ),
      ),
    );
  }

  // --- ฟังก์ชันย่อยสำหรับวาดการ์ดแต่ละใบให้โค้ดดูสะอาด ไม่อัดกันเป็นก้อนเดียว ---

  // การ์ดผลวิเคราะห์
  Widget _buildAiAnalysisCard({
    required ScanResultArgs args,
    required MaterialInfo materialInfo,
  }) {
    return ResultInfoCard(
      title: 'ผลการวิเคราะห์',
      children: [
        ResultKeyValueRow(
          label: 'ผลทำนายจาก',
          value: MaterialCatalog.lookup(args.result.label).displayName,
        ),
        ResultKeyValueRow(
          label: 'ความมั่นใจ',
          value: '${(args.result.confidence * 100).toStringAsFixed(1)}%',
        ),
        if (_isLowConfidence) ...[
          // ถ้าความมั่นใจต่ำ โชว์คำเตือนสีแดง
          const SizedBox(height: 8),
          const ResultWarningText('ความมั่นใจต่ำ — กรุณาตรวจสอบวัสดุด้านล่าง'),
        ],
        const SizedBox(height: 16),
        // ปุ่มให้ผู้ใช้กดแก้ชนิดขยะ (ใช้ UI ที่เราแต่งสีเขียวไว้ในไฟล์ widgets)
        MaterialReviewField(selectedInfo: materialInfo, onTap: _pickMaterial),
        const SizedBox(height: 12),
        ResultKeyValueRow(
          label: 'หมวดหมู่',
          value: materialInfo.category,
        ), // โชว์หมวด
        ResultKeyValueRow(
          label:
              'สถานะการขาย', // โชว์ว่ารับซื้อไหม (ทำตัวอักษรสีเขียวถ้ารับซื้อ)
          value: _isSellable ? 'รับซื้อ' : 'ไม่รับซื้อ',
          valueColor: _isSellable ? Colors.green.shade700 : null,
        ),
        if (!_isSellable) ...[
          // ถ้าไม่รับซื้อ โชว์คำเตือนสีแดง
          const SizedBox(height: 8),
          const ResultWarningText(
            'วัสดุนี้ไม่สามารถขายได้ กรุณากำจัดอย่างเหมาะสม',
          ),
        ],
      ],
    );
  }

  // 🌟 ไฮไลท์ UI: การ์ดกรอกน้ำหนัก (ทำสีพื้นหลังเด่นๆ)
  Widget _buildWeightCard() {
    return ResultInfoCard(
      title: 'กรอกน้ำหนัก',
      children: [
        TextField(
          // ช่องกรอกข้อความ
          controller: _weightController, // เชื่อมตัวดูดข้อความ
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ), // บังคับให้เด้งแป้นพิมพ์ตัวเลข (มีจุดทศนิยมได้)
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ), // ตัวเลขในช่องให้หนาๆ
          decoration: InputDecoration(
            // ตกแต่งช่องพิมพ์
            labelText: 'น้ำหนัก (กก.)',
            hintText: 'ตัวอย่าง: 2.5',
            filled: true, // สั่งให้เทสีพื้นหลัง
            fillColor: Colors.green.shade50, // สีพื้นหลังเขียวอ่อนสุดๆ
            enabledBorder: OutlineInputBorder(
              // เส้นขอบตอนปกติ (สีเขียวอ่อน)
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              // เส้นขอบตอนกำลังเอานิ้วจิ้มพิมพ์ (สีเขียวเข้ม)
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade700, width: 2),
            ),
          ),
          onChanged: (value) {
            // ทันทีที่ผู้ใช้พิมพ์หรือลบตัวเลข...
            setState(() {
              // สั่งวาดหน้าจอใหม่ทันที
              _weightKg =
                  double.tryParse(value) ??
                  0; // แปลงตัวอักษรเป็นตัวเลขคณิตศาสตร์ ถ้าแปลงไม่ได้ให้เป็น 0
            });
          },
        ),
      ],
    );
  }

  // ===========================================================================
  //  การ์ดข้อมูลราคา (ปรับให้เป็นช่องกรอกข้อมูล เพื่อให้ผู้ใช้พิมพ์แก้ราคาได้)
  // ===========================================================================
  Widget _buildPriceCard() {
    // 🔧 E) [แก้ตรงนี้ ลบทิ้ง] บล็อกนี้เคยอยู่ตรงนี้ (ตอนนี้ลบแล้ว) และเป็น "ต้นเหตุของบั๊ก":
    //     if (_priceController.text.isEmpty && _customPricePerKg == null) {
    //       _priceController.text = _pricePerKg.toStringAsFixed(2);
    //     }
    // ทำไมมันผิด: มันเติมราคาแค่ตอน "ช่องว่าง" พอช่องมีเลขเก่าค้างอยู่ (เช่น 35.00)
    //            ก็ไม่ยอมอัปเดตเป็นราคาจริงจาก DB (67.00) อีกเลย
    // และไม่ควรสั่งแก้ Controller ในฟังก์ชันที่วาดหน้าจอ เพราะ build ถูกเรียกซ้ำบ่อยมาก
    // งานเติมราคาย้ายไปอยู่ที่จุด B, C, D แล้ว (เรียก _syncPriceField)

    return ResultInfoCard(
      title: 'ข้อมูลราคา', // หัวข้อการ์ด
      children: [
        // 💡 แปลงร่าง "ราคาต่อกก." ให้เป็นช่องพิมพ์ (TextField)
        TextField(
          controller: _priceController, // เชื่อมกับ Controller ราคา
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
          ), // บังคับแป้นพิมพ์ตัวเลข
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ), // ตัวเลขหนาๆ
          decoration: InputDecoration(
            labelText: 'ราคาต่อกก. (บาท)', // ป้ายลอยด้านบน
            filled: true, // เปิดเทสีพื้นหลัง
            fillColor: Colors
                .green
                .shade50, // สีพื้นหลังเขียวอ่อน สื่อว่าช่องนี้แก้ได้
            enabledBorder: OutlineInputBorder(
              // กรอบตอนปกติ
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              // กรอบตอนกำลังจิ้มพิมพ์
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade700, width: 2),
            ),
          ),
          onChanged: (value) {
            // ทันทีที่ผู้ใช้พิมพ์แก้ราคา
            setState(() {
              _customPricePerKg = double.tryParse(
                value,
              ); // แปลงข้อความที่พิมพ์เป็นตัวเลข (แปลงไม่ได้ = null = กลับไปใช้ราคามาตรฐาน)
            });
          },
        ),
        const SizedBox(height: 12), // เว้นระยะห่าง
        // โชว์ราคาประเมินรวมสุทธิ (คำนวณสด: น้ำหนัก x ราคาที่แก้)
        ResultKeyValueRow(
          label: 'ราคาประเมินสุทธิ',
          value: NumberFormatter.money(_estimatedPrice),
          valueColor: Colors.green.shade800, // เน้นตัวเลขให้เด่นชัด
        ),
        const SizedBox(height: 6),
        const ResultFormulaHint('สูตร: น้ำหนัก × ราคาต่อกก.'), // สูตรคำนวณ
      ],
    );
  }

  // การ์ดโชว์สิ่งแวดล้อม
  Widget _buildEnvironmentCard() {
    return ResultInfoCard(
      title: 'ผลกระทบต่อสิ่งแวดล้อม',
      children: [
        ResultKeyValueRow(
          label: 'CO₂ ที่ลดได้',
          value: NumberFormatter.co2(_co2Saved),
        ),
        ResultKeyValueRow(label: 'คะแนนที่ได้รับ', value: '$_points คะแนน'),
        const SizedBox(height: 6),
        const ResultFormulaHint('สูตร: CO₂ ที่ลดได้ × 10'),
      ],
    );
  }

  // การ์ดเคล็ดลับ (ใช้ลูป for เอาทิปส์ทั้งหมดมาวาดเรียงกัน)
  Widget _buildTipsCard(MaterialInfo materialInfo) {
    return ResultInfoCard(
      title: 'เคล็ดลับการรีไซเคิล',
      children: [for (final tip in materialInfo.tips) ResultTipText(tip)],
    );
  }

  // 🌟 ไฮไลท์ UI: การ์ดกรอกหมายเหตุ (ทำสีพื้นหลังเทาๆ ให้ต่างจากน้ำหนัก)
  Widget _buildNoteCard() {
    return ResultInfoCard(
      title: 'หมายเหตุ',
      children: [
        TextField(
          controller: _noteController,
          minLines: 3, // ความสูงช่องพิมพ์เริ่มต้นคือ 3 บรรทัด
          maxLines: 5, // ถ้ายาวมากให้ยืดได้สูงสุด 5 บรรทัด
          decoration: InputDecoration(
            hintText: 'ตัวอย่าง: เก็บมาจากโรงอาหารโรงเรียน',
            filled: true, // เปิดเทสีพื้นหลัง
            fillColor: Colors.grey.shade100, // เทสีเทาอ่อน
            enabledBorder: OutlineInputBorder(
              // เส้นขอบปกติ
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              // เส้นขอบตอนจิ้มพิมพ์
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.green.shade700,
                width: 2,
              ), // พอจิ้มแล้วขอบเขียว
            ),
          ),
        ),
      ],
    );
  }

  // ปุ่มเซฟล่างสุด
  Widget _buildSaveButton() {
    return PrimaryActionButton(
      // ถ้าขายได้ให้เขียน "บันทึกข้อมูล" ถ้าขายไม่ได้เขียน "บันทึกการสแกน"
      label: _isSellable ? 'บันทึกข้อมูล' : 'บันทึกการสแกน',
      icon: Icons.save_outlined, // ไอคอนเซฟ
      onPressed: _saveRecord, // ฟังก์ชันเซฟที่เตรียมไว้ด้านบน
    );
  }
}
