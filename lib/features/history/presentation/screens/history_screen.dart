import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../features/history/data/models/history_record_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';
import 'history_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final HistoryRepository _historyRepository;

  List<HistoryRecordModel> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _historyRepository = HistoryRepository(database: AppDatabase.instance);

    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final records = await _historyRepository.getAllHistory();

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Failed to load history: $error');

      if (!mounted) return;

      setState(() {
        _records = [];
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('โหลดประวัติไม่สำเร็จ')));
    }
  }

  Future<void> _deleteRecord(HistoryRecordModel record) async {
    if (record.id == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ลบรายการนี้หรือไม่?'),
          content: const Text('รายการนี้จะถูกลบออกจากประวัติในเครื่องของคุณ'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    await _historyRepository.deleteHistory(record.id!);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ลบรายการแล้ว')));

    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF3),
      appBar: AppBar(
        title: const Text('ประวัติ'),
        backgroundColor: const Color(0xFFF7FAF3),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(onRefresh: _loadHistory, child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [_EmptyHistoryView()],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final record = _records[index];

        return _HistoryRecordCard(
          record: record,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HistoryDetailScreen(record: record),
              ),
            );
          },
          onDelete: () => _deleteRecord(record),
        );
      },
    );
  }
}

class _HistoryRecordCard extends StatelessWidget {
  const _HistoryRecordCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  final HistoryRecordModel record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(record.imagePath);
    final hasImage = imageFile.existsSync();

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE4ECE0),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: hasImage
                  ? Image.file(
                      imageFile,
                      width: 92,
                      height: 92,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 92,
                      height: 92,
                      color: Colors.white,
                      child: const Icon(Icons.image_outlined, size: 34),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.material,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E211D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF5E665B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MiniInfoRow(
                    icon: Icons.scale_rounded,
                    text: '${record.weight.toStringAsFixed(2)} กก.',
                  ),
                  const SizedBox(height: 4),
                  _MiniInfoRow(
                    icon: Icons.payments_rounded,
                    text: NumberFormatter.money(record.estimatedPrice),
                  ),
                  const SizedBox(height: 4),
                  _MiniInfoRow(
                    icon: Icons.eco_rounded,
                    text:
                        '${NumberFormatter.co2(record.co2Saved)} • ${record.pointsEarned} คะแนน',
                  ),
                  if (record.note != null &&
                      record.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      record.note!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4F594C),
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(record.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6B7468),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'ลบ',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
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

class _MiniInfoRow extends StatelessWidget {
  const _MiniInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF1F4F28)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E211D),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: BoxDecoration(
        color: const Color(0xFFE4ECE0),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 42,
              color: Color(0xFF1F4F28),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ยังไม่มีประวัติ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E211D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'สแกนและบันทึกวัสดุรีไซเคิลเพื่อดูที่นี่',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5E665B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
