import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../features/history/data/models/history_record_model.dart';
import '../../../../features/history/data/repositories/history_repository.dart';
import '../../../../services/database/app_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.historyLoader});

  /// Lets widget tests provide deterministic history without opening SQLite.
  final Future<List<HistoryRecordModel>> Function()? historyLoader;

  static const Color _background = Color(0xFFF7FAF3);
  static const Color _primaryGreen = Color(0xFF2F7D3A);
  static const Color _darkGreen = Color(0xFF1F4F28);
  static const Color _cardGreen = Color(0xFFE4ECE0);
  static const Color _textDark = Color(0xFF1E211D);
  static const Color _textMuted = Color(0xFF5E665B);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HistoryRepository _historyRepository;

  List<HistoryRecordModel> _records = [];
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();

    _historyRepository = HistoryRepository(database: AppDatabase.instance);

    _loadHistory();
  }

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
      backgroundColor: HomeScreen._background,
      appBar: AppBar(
        backgroundColor: HomeScreen._background,
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
              color: HomeScreen._textDark,
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
              const _AppIntro(),
              const SizedBox(height: 22),
              _ScanHeroCard(onTap: _openScanScreen),
              const SizedBox(height: 28),
              Text(
                'สถิติภาพรวม',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                  color: HomeScreen._textDark,
                ),
              ),
              const SizedBox(height: 16),
              _DashboardGrid(
                totalRecords: _records.length,
                totalEstimatedValue: _totalEstimatedValue,
                totalCo2Saved: _totalCo2Saved,
                totalPoints: _totalPoints,
              ),
              const SizedBox(height: 30),
              _SecondaryActionButton(
                label: 'ดูสถิติ',
                icon: Icons.bar_chart_rounded,
                onPressed: _openStatisticsScreen,
              ),
              const SizedBox(height: 14),
              _SecondaryActionButton(
                label: 'ราคารับซื้อ',
                icon: Icons.price_change_rounded,
                onPressed: _openPriceScreen,
              ),
              const SizedBox(height: 34),
              _SectionHeader(
                title: 'ประวัติล่าสุด',
                actionLabel: 'ดูทั้งหมด',
                onActionTap: _openHistoryScreen,
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const _LoadingHistoryCard()
              else if (_records.isEmpty)
                const _EmptyRecentHistory()
              else
                _RecentHistoryCard(record: _records.first),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIntro extends StatelessWidget {
  const _AppIntro();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        /*Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: HomeScreen._darkGreen,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: HomeScreen._darkGreen.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.recycling_rounded,
            color: Colors.white,
            size: 34,
          ),
        ),*/
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /*Text(
                'Recycle AI',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      color: HomeScreen._textDark,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                'Offline material classifier',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: HomeScreen._textMuted,
                      fontWeight: FontWeight.w500,
                    ),
              ),*/
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanHeroCard extends StatelessWidget {
  const _ScanHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeScreen._primaryGreen,
      borderRadius: BorderRadius.circular(34),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(34),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: HomeScreen._primaryGreen.withValues(alpha: 0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 74,
                width: 74,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: HomeScreen._primaryGreen,
                  size: 38,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Material',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.4,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Take a photo or select from gallery',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  const _DashboardGrid({
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
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.36,
      children: [
        _StatCard(
          icon: Icons.history_rounded,
          value: '$totalRecords',
          label: 'จำนวนรายการ',
        ),
        _StatCard(
          icon: Icons.account_balance_wallet_rounded,
          value: NumberFormatter.money(totalEstimatedValue),
          label: 'มูลค่าประเมิน',
        ),
        _StatCard(
          icon: Icons.eco_rounded,
          value: NumberFormatter.co2(totalCo2Saved),
          label: 'CO₂ ที่ลดได้',
        ),
        _StatCard(
          icon: Icons.star_rounded,
          value: '$totalPoints',
          label: 'คะแนนสะสม',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: HomeScreen._cardGreen,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: HomeScreen._darkGreen),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: HomeScreen._textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF4F594C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF35C21B),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      icon: Icon(icon, size: 26),
      label: Text(label),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: HomeScreen._textDark,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: HomeScreen._primaryGreen,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _RecentHistoryCard extends StatelessWidget {
  const _RecentHistoryCard({required this.record});

  final HistoryRecordModel record;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = File(record.imagePath).existsSync();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HomeScreen._cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: hasImage
                ? Image.file(
                    File(record.imagePath),
                    width: 86,
                    height: 86,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 86,
                    height: 86,
                    color: Colors.white,
                    child: const Icon(Icons.image_outlined),
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
                    color: HomeScreen._textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.weight.toStringAsFixed(2)} กก. • ${NumberFormatter.money(record.estimatedPrice)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HomeScreen._textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormatter.co2(record.co2Saved)} • ${record.pointsEarned} คะแนน',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HomeScreen._darkGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (record.note != null && record.note!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    record.note!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF4F594C),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHistoryCard extends StatelessWidget {
  const _LoadingHistoryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: HomeScreen._cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyRecentHistory extends StatelessWidget {
  const _EmptyRecentHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: HomeScreen._cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 34,
              color: HomeScreen._textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีรายการ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: HomeScreen._textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เริ่มต้นด้วยการสแกนวัสดุรีไซเคิลชิ้นแรกของคุณ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4F594C),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
