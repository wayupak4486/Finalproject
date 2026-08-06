import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/widgets/summary_card.dart';

/// Presentational widgets for [StatisticsScreen]. Kept separate from the
/// screen's history-loading and aggregation logic.

class StatisticsSummaryGrid extends StatelessWidget {
  const StatisticsSummaryGrid({
    required this.totalRecords,
    required this.totalEstimatedValue,
    required this.totalCo2Saved,
    required this.totalPoints,
    super.key,
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

class StatisticsSectionCard extends StatelessWidget {
  const StatisticsSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.cardGreen,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.darkGreen),
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

class StatisticsDistributionList extends StatelessWidget {
  const StatisticsDistributionList({
    required this.data,
    required this.total,
    super.key,
  });

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
              StatisticsLabelValueRow(
                label: entry.key,
                value: '${entry.value} รายการ',
              ),
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

class StatisticsMonthlyActivityList extends StatelessWidget {
  const StatisticsMonthlyActivityList({required this.data, super.key});

  final Map<String, int> data;

  @override
  Widget build(BuildContext context) {
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: StatisticsLabelValueRow(
            label: entry.key,
            value: '${entry.value} records',
          ),
        );
      }).toList(),
    );
  }
}

class StatisticsEnvironmentalSummary extends StatelessWidget {
  const StatisticsEnvironmentalSummary({
    required this.totalCo2Saved,
    required this.totalPoints,
    super.key,
  });

  final double totalCo2Saved;
  final int totalPoints;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.primaryGreen,
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

class StatisticsLabelValueRow extends StatelessWidget {
  const StatisticsLabelValueRow({
    required this.label,
    required this.value,
    super.key,
  });

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
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class StatisticsEmptyText extends StatelessWidget {
  const StatisticsEmptyText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
    );
  }
}
