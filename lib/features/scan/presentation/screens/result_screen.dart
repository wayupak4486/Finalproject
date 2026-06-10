import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/calculation_utils.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../features/history/data/models/history_record_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late final HistoryRepository _historyRepository;
  String? _imagePath;

  static const double _demoPricePerKg = 8.50;
  static const double _demoCo2Factor = 1.50;

  double _weightKg = 0;

  double get _estimatedPrice => CalculationUtils.calculateEstimatedPrice(
    weightKg: _weightKg,
    pricePerKg: _demoPricePerKg,
  );

  double get _co2Saved => CalculationUtils.calculateCo2Saved(
    weightKg: _weightKg,
    co2Factor: _demoCo2Factor,
  );

  int get _points => CalculationUtils.calculatePoints(_co2Saved);

  
  @override
  void initState() {
    super.initState();

    _historyRepository = HistoryRepository(database: AppDatabase.instance);
  }
  
@override
  void dispose() {
    _weightController.dispose();
    _noteController.dispose();
    super.dispose();
  }
Future<void> _saveRecord() async {
  if (_imagePath == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image path not found. Please scan again.'),
      ),
    );
    return;
  }

  final record = HistoryRecordModel(
    imagePath: _imagePath!,
    material: 'PET Plastic Bottle',
    category: 'Plastic',
    confidence: 96.4,
    weight: _weightKg,
    pricePerKg: _demoPricePerKg,
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

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Record saved successfully'),
    ),
  );

  Navigator.popUntil(context, (route) => route.isFirst);
}


  @override
  Widget build(BuildContext context) {
    _imagePath ??= ModalRoute.of(context)?.settings.arguments as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Result & Estimation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CapturedImage(imagePath: _imagePath),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'AI Result',
              children: const [
                _KeyValueRow(label: 'Material', value: 'PET Plastic Bottle'),
                _KeyValueRow(label: 'Category', value: 'Plastic'),
                _KeyValueRow(label: 'Confidence', value: '96.4%'),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Weight Input',
              children: [
                TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    hintText: 'Example: 2.5',
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
              title: 'Price Information',
              children: [
                _KeyValueRow(
                  label: 'Price Per Kg',
                  value: NumberFormatter.money(_demoPricePerKg),
                ),
                _KeyValueRow(
                  label: 'Estimated Price',
                  value: NumberFormatter.money(_estimatedPrice),
                ),
                const SizedBox(height: 6),
                Text(
                  'Formula: Weight × Price Per Kg',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Environmental Impact',
              children: [
                _KeyValueRow(
                  label: 'CO₂ Saved',
                  value: NumberFormatter.co2(_co2Saved),
                ),
                _KeyValueRow(label: 'Points Earned', value: '$_points points'),
                const SizedBox(height: 6),
                Text(
                  'Formula: CO₂ Saved × 10',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _InfoCard(
              title: 'Recycling Tips',
              children: [
                _TipText('Remove liquid residue'),
                _TipText('Clean bottle'),
                _TipText('Separate cap'),
                _TipText('Compress bottle'),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Note',
              children: [
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Example: Collected from school cafeteria',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _weightKg <= 0 ? null : _saveRecord,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Record'),
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
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
