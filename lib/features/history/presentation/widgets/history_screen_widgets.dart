import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../data/models/history_record_model.dart';

/// Presentational widgets for [HistoryScreen]. Kept separate from the
/// screen's history-loading and delete-confirmation logic.

class HistoryRecordCard extends StatelessWidget {
  const HistoryRecordCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
    super.key,
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
          color: AppColors.cardGreen,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.cardBorder),
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
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    record.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  HistoryMiniInfoRow(
                    icon: Icons.scale_rounded,
                    text: '${record.weight.toStringAsFixed(2)} กก.',
                  ),
                  const SizedBox(height: 4),
                  HistoryMiniInfoRow(
                    icon: Icons.payments_rounded,
                    text: NumberFormatter.money(record.estimatedPrice),
                  ),
                  const SizedBox(height: 4),
                  HistoryMiniInfoRow(
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
                        color: AppColors.textMutedSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    DateFormatter.slashDateTime(record.createdAt),
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
}

class HistoryMiniInfoRow extends StatelessWidget {
  const HistoryMiniInfoRow({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.darkGreen),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.cardBorder),
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
              color: AppColors.darkGreen,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ยังไม่มีประวัติ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'สแกนและบันทึกวัสดุรีไซเคิลเพื่อดูที่นี่',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
