import 'package:flutter/material.dart';

import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/summary_card.dart';
import '../../../../features/history/data/models/history_record_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final HistoryRepository _historyRepository;

  List<HistoryRecordModel> _records = [];
  bool _isLoading = true;

  int get _totalRecords => _records.length;

  double get _totalEstimatedValue {
    return _records.fold<double>(
      0,
      (sum, record) => sum + record.estimatedPrice,
    );
  }

  double get _totalCo2Saved {
    return _records.fold<double>(0, (sum, record) => sum + record.co2Saved);
  }

  int get _totalPoints {
    return _records.fold<int>(0, (sum, record) => sum + record.pointsEarned);
  }

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
      backgroundColor: const Color(0xFFF7FAF3),
      appBar: AppBar(
        title: const Text('สถิติ'),
        backgroundColor: const Color(0xFFF7FAF3),
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
                    _SummaryGrid(
                      totalRecords: _totalRecords,
                      totalEstimatedValue: _totalEstimatedValue,
                      totalCo2Saved: _totalCo2Saved,
                      totalPoints: _totalPoints,
                    ),
                    const SizedBox(height: 24),
                    _SectionCard(
                      title: 'สัดส่วนวัสดุ',
                      icon: Icons.pie_chart_rounded,
                      child: _records.isEmpty
                          ? const _EmptyText('ยังไม่มีข้อมูลวัสดุ')
                          : _DistributionList(
                              data: _materialDistribution,
                              total: _totalRecords,
                            ),
                    ),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'กิจกรรมรายเดือน',
                      icon: Icons.bar_chart_rounded,
                      child: _records.isEmpty
                          ? const _EmptyText('ยังไม่มีกิจกรรมรายเดือน')
                          : _MonthlyActivityList(data: _monthlyActivity),
                    ),
                    const SizedBox(height: 16),
                    _EnvironmentalSummary(
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

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.totalRecords,
    required this.totalEstimatedValue,
    required this.totalCo2Saved,
    required this.totalPoints,
  });

  final int totalRecords;
  final double totalEstimatedValue;
  final double totalCo2Saved;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        SummaryCard(
          icon: Icons.history,
          title: 'จำนวนรายการ',
          value: '$totalRecords',
        ),
        SummaryCard(
          icon: Icons.payments_outlined,
          title: 'มูลค่าประเมิน',
          value: NumberFormatter.money(totalEstimatedValue),
        ),
        SummaryCard(
          icon: Icons.eco_outlined,
          title: 'CO₂ ที่ลดได้',
          value: NumberFormatter.co2(totalCo2Saved),
        ),
        SummaryCard(
          icon: Icons.star_outline,
          title: 'คะแนนสะสม',
          value: '$totalPoints',
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFE4ECE0),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1F4F28)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _DistributionList extends StatelessWidget {
  const _DistributionList({required this.data, required this.total});

  final Map<String, int> data;
  final int total;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: entries.map((entry) {
        final percent = total == 0 ? 0.0 : entry.value / total;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LabelValueRow(label: entry.key, value: '${entry.value} รายการ'),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _MonthlyActivityList extends StatelessWidget {
  const _MonthlyActivityList({required this.data});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LabelValueRow(
            label: entry.key,
            value: '${entry.value} records',
          ),
        );
      }).toList(),
    );
  }
}

class _EnvironmentalSummary extends StatelessWidget {
  const _EnvironmentalSummary({
    required this.totalCo2Saved,
    required this.totalPoints,
  });

  final double totalCo2Saved;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2F7D3A),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.park_rounded, color: Colors.white, size: 38),
            const SizedBox(height: 14),
            Text(
              'ผลกระทบเชิงบวกต่อสิ่งแวดล้อม',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'คุณลดคาร์บอนได้ ${NumberFormatter.co2(totalCo2Saved)} และได้รับ $totalPoints คะแนนจากกิจกรรมรีไซเคิล',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  const _LabelValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1F4F28),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF5E665B)),
    );
  }
}
