import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../features/history/data/models/history_record_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';
import '../widgets/statistics_screen_widgets.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final HistoryRepository _historyRepository;

  List<HistoryRecordModel> _records = [];
  bool _isLoading = true;

  // Derived values

  int get _totalRecords => _records.length;
  double get _totalEstimatedValue => _records.totalEstimatedPrice;
  double get _totalCo2Saved => _records.totalCo2Saved;
  int get _totalPoints => _records.totalPointsEarned;

  Map<String, int> get _materialDistribution {
    final result = <String, int>{};

    for (final record in _records) {
      result[record.material] = (result[record.material] ?? 0) + 1;
    }

    return result;
  }

  Map<String, int> get _monthlyActivity {
    final result = <String, int>{};

    for (final record in _records) {
      final month =
          '${record.createdAt.month.toString().padLeft(2, '0')}/${record.createdAt.year}';
      result[month] = (result[month] ?? 0) + 1;
    }

    return result;
  }

  @override
  void initState() {
    super.initState();

    _historyRepository = HistoryRepository(database: AppDatabase.instance);

    _loadStatistics();
  }

  // Data fetching

  Future<void> _loadStatistics() async {
    try {
      final records = await _historyRepository.getAllHistory();

      if (!mounted) return;

      setState(() {
        _records = records;
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Failed to load statistics: $error');

      if (!mounted) return;

      setState(() {
        _records = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สถิติ'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _loadStatistics,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStatistics,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    StatisticsSummaryGrid(
                      totalRecords: _totalRecords,
                      totalEstimatedValue: _totalEstimatedValue,
                      totalCo2Saved: _totalCo2Saved,
                      totalPoints: _totalPoints,
                    ),
                    const SizedBox(height: 24),
                    StatisticsSectionCard(
                      title: 'สัดส่วนวัสดุ',
                      icon: Icons.pie_chart_rounded,
                      child: _records.isEmpty
                          ? const StatisticsEmptyText('ยังไม่มีข้อมูลวัสดุ')
                          : StatisticsDistributionList(
                              data: _materialDistribution,
                              total: _totalRecords,
                            ),
                    ),
                    const SizedBox(height: 16),
                    StatisticsSectionCard(
                      title: 'กิจกรรมรายเดือน',
                      icon: Icons.bar_chart_rounded,
                      child: _records.isEmpty
                          ? const StatisticsEmptyText('ยังไม่มีกิจกรรมรายเดือน')
                          : StatisticsMonthlyActivityList(
                              data: _monthlyActivity,
                            ),
                    ),
                    const SizedBox(height: 16),
                    StatisticsEnvironmentalSummary(
                      totalCo2Saved: _totalCo2Saved,
                      totalPoints: _totalPoints,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
