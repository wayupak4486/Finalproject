import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/history/data/models/history_record_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';
import '../widgets/home_screen_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.historyLoader});

  /// Lets widget tests provide deterministic history without opening SQLite.
  final Future<List<HistoryRecordModel>> Function()? historyLoader;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HistoryRepository _historyRepository;

  List<HistoryRecordModel> _records = [];
  bool _isLoading = true;

  double get _totalEstimatedValue => _records.totalEstimatedPrice;
  double get _totalCo2Saved => _records.totalCo2Saved;
  int get _totalPoints => _records.totalPointsEarned;

  @override
  void initState() {
    super.initState();

    _historyRepository = HistoryRepository(database: AppDatabase.instance);

    _loadHistory();
  }

  // Data fetching

  Future<void> _loadHistory() async {
    try {
      final records =
          await (widget.historyLoader?.call() ??
              _historyRepository.getAllHistory());

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
    }
  }

  // Navigation

  Future<void> _openScanScreen() async {
    await Navigator.pushNamed(context, AppRoutes.scan);
    await _loadHistory();
  }

  Future<void> _openHistoryScreen() async {
    await Navigator.pushNamed(context, AppRoutes.history);
    await _loadHistory();
  }

  Future<void> _openStatisticsScreen() async {
    await Navigator.pushNamed(context, AppRoutes.statistics);
    await _loadHistory();
  }

  Future<void> _openPriceScreen() async {
    await Navigator.pushNamed(context, AppRoutes.prices);
    await _loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              tooltip: 'ตั้งค่า',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
              icon: const Icon(Icons.settings_rounded),
              iconSize: 32,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHistory,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              const HomeAppIntro(),
              const SizedBox(height: 22),
              HomeScanHeroCard(onTap: _openScanScreen),
              const SizedBox(height: 28),
              Text(
                'สถิติภาพรวม',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              HomeDashboardGrid(
                totalRecords: _records.length,
                totalEstimatedValue: _totalEstimatedValue,
                totalCo2Saved: _totalCo2Saved,
                totalPoints: _totalPoints,
              ),
              const SizedBox(height: 30),
              HomeSecondaryActionButton(
                label: 'ดูสถิติ',
                icon: Icons.bar_chart_rounded,
                onPressed: _openStatisticsScreen,
              ),
              const SizedBox(height: 14),
              HomeSecondaryActionButton(
                label: 'ราคารับซื้อ',
                icon: Icons.price_change_rounded,
                onPressed: _openPriceScreen,
              ),
              const SizedBox(height: 34),
              HomeSectionHeader(
                title: 'ประวัติล่าสุด',
                actionLabel: 'ดูทั้งหมด',
                onActionTap: _openHistoryScreen,
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const HomeLoadingHistoryCard()
              else if (_records.isEmpty)
                const HomeEmptyRecentHistory()
              else
                HomeRecentHistoryCard(record: _records.first),
            ],
          ),
        ),
      ),
    );
  }
}
