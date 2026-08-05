import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/material_catalog.dart';
import '../../../../core/utils/calculation_utils.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../features/history/data/models/history_record_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../features/prices/data/repositories/material_price_repository.dart';
import '../../../../services/database/app_database.dart';
import '../../data/models/scan_result_args.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late final HistoryRepository _historyRepository;
  late final MaterialPriceRepository _priceRepository;
  ScanResultArgs? _args;
  String? _selectedLabel;

  Map<String, double> _livePrices = {};
  double _weightKg = 0;

  MaterialInfo get _materialInfo =>
      MaterialCatalog.lookup(_selectedLabel ?? _args!.result.label);

  bool get _isSellable => _materialInfo.isSellable;

  double get _pricePerKg => _isSellable
      ? _livePrices[_selectedLabel ?? _args!.result.label] ??
            _materialInfo.pricePerKg
      : 0;

  bool get _isLowConfidence =>
      _args!.result.confidence < AppConstants.lowConfidenceThreshold;

  double get _estimatedPrice => CalculationUtils.calculateEstimatedPrice(
    weightKg: _weightKg,
    pricePerKg: _pricePerKg,
  );

  double get _co2Saved => CalculationUtils.calculateCo2Saved(
    weightKg: _weightKg,
    co2Factor: _materialInfo.co2FactorPerKg,
  );

  int get _points => CalculationUtils.calculatePoints(_co2Saved);

  @override
  void initState() {
    super.initState();

    _historyRepository = HistoryRepository(database: AppDatabase.instance);
    _priceRepository = MaterialPriceRepository(database: AppDatabase.instance);

    _loadLivePrices();
  }

  Future<void> _loadLivePrices() async {
    try {
      final prices = await _priceRepository.getPricesByLabel();

      if (!mounted) return;

      setState(() {
        _livePrices = prices;
      });
    } catch (error) {
      debugPrint('Failed to load live prices: $error');
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    final args = _args;
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบพาธรูปภาพ กรุณาสแกนใหม่อีกครั้ง')),
      );
      return;
    }

    final record = HistoryRecordModel(
      imagePath: args.imagePath,
      material: _materialInfo.displayName,
      category: _materialInfo.category,
      confidence: args.result.confidence * 100,
      weight: _weightKg,
      pricePerKg: _pricePerKg,
      estimatedPrice: _estimatedPrice,
      co2Saved: _co2Saved,
      pointsEarned: _points,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    await _historyRepository.insertHistory(record);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')));

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    _args ??= ModalRoute.of(context)?.settings.arguments as ScanResultArgs?;
    final args = _args;

    if (args == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ผลลัพธ์และการประเมิน')),
        body: const Center(
          child: Text('ไม่พบข้อมูลการสแกน กรุณาสแกนใหม่อีกครั้ง'),
        ),
      );
    }

    _selectedLabel ??= args.result.label;
    final materialInfo = _materialInfo;

    return Scaffold(
      appBar: AppBar(title: const Text('ผลลัพธ์และการประเมิน')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CapturedImage(imagePath: args.imagePath),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'ผลการวิเคราะห์ AI',
              children: [
                _KeyValueRow(
                  label: 'ผลทำนายจาก AI',
                  value: MaterialCatalog.lookup(args.result.label).displayName,
                ),
                _KeyValueRow(
                  label: 'ความมั่นใจ',
                  value:
                      '${(args.result.confidence * 100).toStringAsFixed(1)}%',
                ),
                if (_isLowConfidence) ...[
                  const SizedBox(height: 8),
                  Text(
                    'ความมั่นใจต่ำ — กรุณาตรวจสอบวัสดุด้านล่าง',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLabel,
                  decoration: const InputDecoration(
                    labelText: 'ยืนยันวัสดุ',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final entry in MaterialCatalog.byLabel.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value.displayName),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLabel = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _KeyValueRow(label: 'หมวดหมู่', value: materialInfo.category),
                _KeyValueRow(
                  label: 'สถานะการขาย',
                  value: _isSellable ? 'รับซื้อ' : 'ไม่รับซื้อ',
                  valueColor: _isSellable ? Colors.green : null,
                ),
                if (!_isSellable) ...[
                  const SizedBox(height: 8),
                  Text(
                    'วัสดุนี้ไม่สามารถขายได้ กรุณากำจัดอย่างเหมาะสม',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (_isSellable) ...[
              const SizedBox(height: 16),
              _InfoCard(
                title: 'กรอกน้ำหนัก',
                children: [
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'น้ำหนัก (กก.)',
                      hintText: 'ตัวอย่าง: 2.5',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _weightKg = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'ข้อมูลราคา',
                children: [
                  _KeyValueRow(
                    label: 'ราคาต่อกก.',
                    value: NumberFormatter.money(_pricePerKg),
                  ),
                  _KeyValueRow(
                    label: 'ราคาประเมิน',
                    value: NumberFormatter.money(_estimatedPrice),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'สูตร: น้ำหนัก × ราคาต่อกก.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'ผลกระทบต่อสิ่งแวดล้อม',
                children: [
                  _KeyValueRow(
                    label: 'CO₂ ที่ลดได้',
                    value: NumberFormatter.co2(_co2Saved),
                  ),
                  _KeyValueRow(
                    label: 'คะแนนที่ได้รับ',
                    value: '$_points คะแนน',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'สูตร: CO₂ ที่ลดได้ × 10',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _InfoCard(
              title: 'เคล็ดลับการรีไซเคิล',
              children: [for (final tip in materialInfo.tips) _TipText(tip)],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'หมายเหตุ',
              children: [
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'ตัวอย่าง: เก็บมาจากโรงอาหารโรงเรียน',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSellable && _weightKg <= 0 ? null : _saveRecord,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: Text(_isSellable ? 'บันทึกข้อมูล' : 'บันทึกการสแกน'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapturedImage extends StatelessWidget {
  const _CapturedImage({required this.imagePath});

  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imagePath != null && File(imagePath!).existsSync();

    if (!hasImage) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: Icon(Icons.image_outlined, size: 64)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.file(
        File(imagePath!),
        height: 240,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _TipText extends StatelessWidget {
  const _TipText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
