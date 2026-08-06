import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/history_record_model.dart';
import '../../data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';
import '../widgets/history_screen_widgets.dart';
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

  // Data fetching

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

  // Event handlers

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ประวัติ'),
        backgroundColor: AppColors.background,
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
        children: const [HistoryEmptyView()],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _records.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final record = _records[index];

        return HistoryRecordCard(
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
