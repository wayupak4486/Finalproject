import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../features/history/data/models/history_record_model.dart';

/// Presentational widgets for [HomeScreen]. Kept separate from the screen's
/// state/business logic so that file stays focused on data loading and
/// navigation.

class HomeAppIntro extends StatelessWidget {
  const HomeAppIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(width: 16),
        Expanded(child: Column()),
      ],
    );
  }
}

class HomeScanHeroCard extends StatelessWidget {
  const HomeScanHeroCard({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryGreen,
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
                color: AppColors.primaryGreen.withValues(alpha: 0.22),
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
                  color: AppColors.primaryGreen,
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

class HomeDashboardGrid extends StatelessWidget {
  const HomeDashboardGrid({
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
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.36,
      children: [
        HomeStatCard(
          icon: Icons.history_rounded,
          value: '$totalRecords',
          label: 'จำนวนรายการ',
        ),
        HomeStatCard(
          icon: Icons.account_balance_wallet_rounded,
          value: NumberFormatter.money(totalEstimatedValue),
          label: 'มูลค่าประเมิน',
        ),
        HomeStatCard(
          icon: Icons.eco_rounded,
          value: NumberFormatter.co2(totalCo2Saved),
          label: 'CO₂ ที่ลดได้',
        ),
        HomeStatCard(
          icon: Icons.star_rounded,
          value: '$totalPoints',
          label: 'คะแนนสะสม',
        ),
      ],
    );
  }
}

class HomeStatCard extends StatelessWidget {
  const HomeStatCard({
    required this.icon,
    required this.value,
    required this.label,
    super.key,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: AppColors.darkGreen),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMutedSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSecondaryActionButton extends StatelessWidget {
  const HomeSecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
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

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    super.key,
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
              color: AppColors.textDark,
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppColors.primaryGreen,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class HomeRecentHistoryCard extends StatelessWidget {
  const HomeRecentHistoryCard({required this.record, super.key});

  final HistoryRecordModel record;

  @override
  Widget build(BuildContext context) {
    final bool hasImage = File(record.imagePath).existsSync();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
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
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.weight.toStringAsFixed(2)} กก. • ${NumberFormatter.money(record.estimatedPrice)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${NumberFormatter.co2(record.co2Saved)} • ${record.pointsEarned} คะแนน',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkGreen,
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
                      color: AppColors.textMutedSecondary,
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

class HomeLoadingHistoryCard extends StatelessWidget {
  const HomeLoadingHistoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 42),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class HomeEmptyRecentHistory extends StatelessWidget {
  const HomeEmptyRecentHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
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
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ยังไม่มีรายการ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เริ่มต้นด้วยการสแกนวัสดุรีไซเคิลชิ้นแรกของคุณ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMutedSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
