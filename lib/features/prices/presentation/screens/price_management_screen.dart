import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../services/database/app_database.dart';
import '../../data/models/material_price_model.dart';
import '../../data/repositories/material_price_repository.dart';
import '../widgets/price_screen_widgets.dart';

// ===========================================================================
// 📱 หน้าจัดการราคารับซื้อ (PriceManagementScreen)
// ---------------------------------------------------------------------------
// 📌 หน้าที่: ดึงราคาจาก SQLite มาโชว์ และเปิดให้ผู้ใช้กดแก้ราคา (Update) ได้ด้วยตัวเอง
// ===========================================================================
class PriceManagementScreen extends StatefulWidget {
  const PriceManagementScreen({super.key});

  @override
  State<PriceManagementScreen> createState() => _PriceManagementScreenState();
}

class _PriceManagementScreenState extends State<PriceManagementScreen> {
  // =========================================================================
  // 📦 โซนที่ 1: พจนานุกรมตัวแปร (Variables)
  // =========================================================================
  
  // ตัวเชื่อมต่อ SQLite
  late final MaterialPriceRepository _priceRepository;

  // ถังเก็บข้อมูลรายการราคา
  List<MaterialPriceModel> _prices = [];
  
  // สถานะเปิด/ปิด โหลดตรงกลางจอ
  bool _isLoading = true;
  
  // กล่องเก็บข้อความ Error 
  String? _errorMessage;
  
  // ตัวแปรเก็บว่า "กำลังเซฟราคาของวัสดุชื่ออะไรอยู่?" 
  // (เอาไว้วาดวงกลมโหลดกระจุ๋มกระจิ๋มเฉพาะที่บรรทัดนั้น)
  String? _savingLabel;

  // =========================================================================
  // ⚙️ โซนที่ 2: วงจรชีวิตหน้าจอ (Lifecycle)
  // =========================================================================
  @override
  void initState() {
    super.initState();
    _priceRepository = MaterialPriceRepository(database: AppDatabase.instance);
    _loadPrices(); // ดึงข้อมูลราคามาโชว์ทันที
  }

  // =========================================================================
  // 🛠️ โซนที่ 3: พจนานุกรมฟังก์ชันหลังบ้าน (Database Operations)
  // =========================================================================

  // -------------------------------------------------------------------------
  // 📡 ฟังก์ชัน: _loadPrices (โหลดราคาทั้งหมด)
  // -------------------------------------------------------------------------
  Future<bool> _loadPrices({bool showLoading = true}) async {
    // ถ้าตั้งให้โชว์วงกลมโหลด ให้เคลียร์ Error เก่าทิ้งก่อน
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // สั่ง SQLite ขอดูข้อมูลราคาทั้งหมดหน่อย
      final prices = await _priceRepository.getAllPrices();
      if (!mounted) return false; // ถ้าผู้ใช้ปิดหน้าหนีไปแล้ว ไม่ต้องทำต่อ

      // อัปเดตหน้าจอ โชว์ราคา ปิดวงกลมโหลด
      setState(() {
        _prices = prices;
        _isLoading = false;
        _errorMessage = null;
      });
      return true;
      
    } catch (error) {
      if (!mounted) return false;

      // ถ้าพัง ให้ซ่อนวงกลมโหลด แล้วโชว์ข้อความ Error สีแดงแทน
      setState(() {
        _isLoading = false;
        _errorMessage = 'โหลดราคาไม่สำเร็จ: $error';
      });
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // ✏️ ฟังก์ชัน: _editPrice (หน้าต่าง Pop-up พิมพ์แก้ราคา)
  // -------------------------------------------------------------------------
  Future<void> _editPrice(MaterialPriceModel price) async {
    // 💡 ทริคตอบกรรมการ: "GlobalKey<FormState> คือกุญแจที่เอาไว้ล็อกฟอร์มครับ 
    // ถ้าผู้ใช้กรอกผิดกฎที่เราตั้งไว้ เราจะใช้กุญแจนี้สั่งห้ามไม่ให้เซฟได้ครับ"
    final formKey = GlobalKey<FormState>();
    
    // ตั้งค่าราคาตั้งต้นก่อนแก้
    var updatedPrice = price.pricePerKg;

    // เด้งหน้าต่าง Pop-up (AlertDialog) แล้วรอจนกว่าผู้ใช้จะกดยืนยัน (await)
    final confirmedPrice = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('แก้ไขราคา${price.displayName}'), // 🛠️ วิธีแก้โค้ด: แก้หัวเรื่อง Pop-up
        
        content: Form(
          key: formKey, // เสียบกุญแจเข้าฟอร์ม
          
          child: TextFormField( // กล่องพิมพ์ข้อความ
            initialValue: price.pricePerKg.toStringAsFixed(2), // โชว์ราคาเดิมรอไว้เลย
            autofocus: true, // เด้งคีย์บอร์ดให้ทันที ไม่ต้องกดซ้ำ
            keyboardType: const TextInputType.numberWithOptions(decimal: true), // แป้นตัวเลขและจุด
            decoration: const InputDecoration(
              labelText: 'ราคาต่อกิโลกรัม (บาท)',
              suffixText: 'บาท/กก.',
            ),
            
            // 🛡️ ระบบป้องกันผู้ใช้กรอกมั่ว (Validator)
            validator: (value) {
              // 1. ลองแปลงข้อความเป็นตัวเลข
              final parsed = double.tryParse(value?.trim() ?? '');
              
              // 2. ถ้าแปลงไม่ได้ (อาจจะพิมพ์ กขค) หรือเป็นค่าแปลกๆ (NaN) 
              if (parsed == null || !parsed.isFinite) {
                return 'กรุณากรอกราคาเป็นตัวเลขที่ถูกต้อง'; // 🛠️ แก้ข้อความด่าผู้ใช้ตรงนี้
              }
              // 3. ถ้าราคาติดลบ (-5 บาท)
              if (parsed < 0) {
                return 'ราคาต้องไม่ติดลบ';
              }
              // ถ้าผ่านหมด คืนค่า null (แปลว่าไม่มี Error)
              return null;
            },
            
            // ถ้า Validator ด้านบนบอกว่าผ่าน! ให้ดึงตัวเลขนั้นมาเก็บใส่ตัวแปร updatedPrice
            onSaved: (value) {
              updatedPrice = double.parse(value!.trim());
            },
          ),
        ),
        actions: [
          // ปุ่ม 1: ยกเลิก
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // ปิด Pop-up (ไม่ได้ค่าอะไรกลับไป)
            child: const Text('ยกเลิก'),
          ),
          
          // ปุ่ม 2: บันทึก
          FilledButton(
            onPressed: () {
              // ตรวจ Validator ก่อน ถ้ากรอกผิดให้เด้ง Error แล้วหยุดทำงาน
              if (!formKey.currentState!.validate()) return;
              
              // ถ้ากรอกถูก สั่ง OnSaved
              formKey.currentState!.save();
              
              // ปิด Pop-up แล้วโยนตัวเลข updatedPrice กลับไปให้หน้าจอหลัก
              Navigator.pop(dialogContext, updatedPrice);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    // ถ้าผู้ใช้กดยกเลิก (ได้ค่า null) หรือสลับแอปหนีไป ให้จบการทำงาน
    if (confirmedPrice == null || !mounted) return;

    // ----- เข้าสู่โหมดบันทึกข้อมูลลงฐานข้อมูล -----
    setState(() {
      _savingLabel = price.label; // สั่งให้บรรทัดนี้โชว์วงกลมโหลดเล็กๆ แทนปุ่มดินสอ
    });

    try {
      // เรียกบุรุษไปรษณีย์ เอาตัวเลขที่แก้เสร็จแล้วไปเซฟทับ SQLite 
      await _priceRepository.upsertPrice(
        label: price.label,
        pricePerKg: confirmedPrice,
        source: 'manual', // 💡 ทริคตอบกรรมการ: "ผมประทับตราว่า source คือ manual เพื่อให้ระบบรู้ว่าราคานี้คนพิมพ์แก้เอง ไม่ใช่ Web Scraper ดึงมาครับ"
        updatedAt: DateTime.now(),
      );

      // โหลดราคาใหม่มาโชว์ (แบบซ่อนวงกลมโหลดใหญ่)
      final reloaded = await _loadPrices(showLoading: false);
      if (!mounted) return;

      // โชว์ป้าย SnackBar แจ้งว่าเสร็จแล้ว
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(reloaded ? 'บันทึกราคา${price.displayName}แล้ว' : 'บันทึกราคาแล้ว แต่โหลดรายการใหม่ไม่สำเร็จ'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('บันทึกราคาไม่สำเร็จ: $error')));
    } finally {
      // ทำเสร็จหมดแล้ว (ไม่ว่าจะพังหรือสำเร็จ) ให้ปิดวงกลมโหลดที่บรรทัดนั้น
      if (mounted) {
        setState(() {
          _savingLabel = null;
        });
      }
    }
  }

  // =========================================================================
  // 🎨 โซนที่ 4: วาดหน้าจอ (Build UI)
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'จัดการราคา',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900, fontSize: PriceStyle.appBarTitleFontSize),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      
      body: SafeArea(
        child: _isLoading
            // 1. ถ้ากำลังโหลดโชว์วงกลมตรงกลาง
            ? const Center(child: CircularProgressIndicator())
            
            // 2. ถ้าโหลดเสร็จแต่มี Error โชว์กล่องแดง
            : _errorMessage != null
            ? _buildErrorView()
            
            // 3. ปกติ: โชว์ข้อมูล
            : RefreshIndicator( // ดึงจอลงเพื่อโหลด
                onRefresh: _loadPrices,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    _buildHeaderCard(context), // วาดป้ายหัวข้อด้านบนสุด
                    const SizedBox(height: 18),
                    
                    // 4. ถ้าไม่มีข้อมูลเลย
                    if (_prices.isEmpty)
                      _buildEmptyState(context)
                    else
                      // 5. มีข้อมูล: วนลูปวาดการ์ดออกมาทีละใบ
                      for (final price in _prices) ...[
                        _buildPriceCard(context, price),
                        const SizedBox(height: 14),
                      ],
                  ],
                ),
              ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 🧩 วิดเจ็ตย่อย 1: ป้ายข้อความแนะนำด้านบนสุด
  // -------------------------------------------------------------------------
  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardGreen, borderRadius: BorderRadius.circular(28), border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text( // 🛠️ แก้ข้อความหัวเรื่องตรงนี้
            'จัดการราคารับซื้อวัสดุรีไซเคิล',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: PriceStyle.headerTitleFontSize),
          ),
          const SizedBox(height: 8),
          Text( // 🛠️ แก้ข้อความอธิบายตรงนี้
            'แก้ไขราคามาตรฐานที่จัดเก็บใน SQLite เพื่อใช้ในการประเมินมูลค่าวัสดุ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w500, fontSize: PriceStyle.headerSubtitleFontSize),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 🧩 วิดเจ็ตย่อย 2: การ์ดราคา 1 ใบ พร้อมปุ่มดินสอ
  // -------------------------------------------------------------------------
  Widget _buildPriceCard(BuildContext context, MaterialPriceModel price) {
    // เช็คว่าการ์ดใบนี้ คือการ์ดที่กำลังกดเซฟอยู่ใช่ไหม? (True/False)
    final isSaving = _savingLabel == price.label;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGreen, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // ไอคอนรีไซเคิล
          Container(
            height: 52, width: 52,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Icon(Icons.recycling_rounded, color: AppColors.primaryGreen, size: PriceStyle.cardIconSize), // 🛠️ เปลี่ยนไอคอนตรงนี้
          ),
          const SizedBox(width: 14),
          
          // พื้นที่ข้อความตรงกลาง
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: PriceStyle.cardTitleFontSize)),
                const SizedBox(height: 3),
                Text(price.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: PriceStyle.cardSubtitleFontSize)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          
          // โซนราคาและปุ่มดินสอ (ชิดขวา)
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // โชว์ราคา
              Text(
                '${NumberFormatter.money(price.pricePerKg)}/กก.',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primaryGreen, fontSize: PriceStyle.cardPriceFontSize),
              ),
              
              // 🛠️ ไฮไลท์สำคัญ: ปุ่มดินสอ
              SizedBox(
                height: 40,
                child: isSaving
                    // ถ้ากำลังเซฟอยู่ -> วาดวงกลมโหลดเล็กๆ 20 พิกเซล
                    ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                    
                    // ถ้าปกติ -> วาดปุ่มดินสอ (ถ้ากดปุ๊บ ให้วิ่งไปรันฟังก์ชัน _editPrice ด้านบน)
                    : IconButton(
                        tooltip: 'แก้ไขราคา',
                        visualDensity: VisualDensity.compact,
                        onPressed: _savingLabel == null ? () => _editPrice(price) : null,
                        icon: const Icon(Icons.edit_rounded),
                        color: AppColors.primaryGreen,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 🧩 วิดเจ็ตย่อย 3: หน้าโล่งๆ เวลาไม่มีราคา
  // -------------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.cardGreen, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.cardBorder)),
      child: Text(
        'ยังไม่มีข้อมูลราคา', // 🛠️ แก้ข้อความได้ที่นี่
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted, fontWeight: FontWeight.w600),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 🧩 วิดเจ็ตย่อย 4: หน้าจอเวลา Database พัง (โชว์ปุ่มลองใหม่)
  // -------------------------------------------------------------------------
  Widget _buildErrorView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        PriceErrorBanner(message: _errorMessage!), // นำเข้าจากไฟล์อื่น
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _loadPrices, // กดแล้วลองโหลดข้อมูลใหม่
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryGreen, foregroundColor: Colors.white,
            minimumSize: Size.fromHeight(PriceStyle.updateButtonHeight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: PriceStyle.updateButtonFontSize),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 28),
          label: const Text('ลองอีกครั้ง'),
        ),
      ],
    );
  }
}