import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../data/models/history_record_model.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.record});

  final HistoryRecordModel record;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(record.imagePath);
    final hasImage = imageFile.existsSync();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF3),
      appBar: AppBar(
        title: const Text('รายละเอียดประวัติ'),
        backgroundColor: const Color(0xFFF7FAF3),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: hasImage
                  ? Image.file(
                      imageFile,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 260,
                      width: double.infinity,
                      color: const Color(0xFFE4ECE0),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 72,
                        color: Color(0xFF1F4F28),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'ผลการวิเคราะห์ AI',
              children: [
                _DetailRow(label: 'วัสดุ', value: record.material),
                _DetailRow(label: 'หมวดหมู่', value: record.category),
                _DetailRow(
                  label: 'ความมั่นใจ',
                  value: '${record.confidence.toStringAsFixed(1)}%',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'ประเมินราคา',
              children: [
                _DetailRow(
                  label: 'น้ำหนัก',
                  value: '${record.weight.toStringAsFixed(2)} กก.',
                ),
                _DetailRow(
                  label: 'ราคา/กก.',
                  value: NumberFormatter.money(record.pricePerKg),
                ),
                _DetailRow(
                  label: 'ราคาประเมิน',
                  value: NumberFormatter.money(record.estimatedPrice),
                  isHighlight: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'ผลกระทบต่อสิ่งแวดล้อม',
              children: [
                _DetailRow(
                  label: 'CO₂ ที่ลดได้',
                  value: NumberFormatter.co2(record.co2Saved),
                ),
                _DetailRow(
                  label: 'คะแนนที่ได้รับ',
                  value: '${record.pointsEarned} คะแนน',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'ข้อมูลเพิ่มเติม',
              children: [
                _DetailRow(label: 'หมายเหตุ', value: _safeNote(record.note)),
                _DetailRow(
                  label: 'สร้างเมื่อ',
                  value: _formatDate(record.createdAt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _safeNote(String? note) {
    if (note == null || note.trim().isEmpty) {
      return '-';
    }

    return note.trim();
  }

  static String _formatDate(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE4ECE0),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E211D),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    final valueColor = isHighlight
        ? const Color(0xFF1F7A35)
        : const Color(0xFF1E211D);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF5E665B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
