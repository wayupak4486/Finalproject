import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../services/price_source/wongpanit_price_service.dart';
import '../../data/models/material_price_model.dart';

/// Presentational widgets for [PriceScreen]. Kept separate from the
/// screen's price-loading and web-update logic.

class PriceHeaderCard extends StatelessWidget {
  const PriceHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตารางราคารับซื้อวัสดุรีไซเคิล',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'แอปดึงรายการราคารับซื้อล่าสุดจากเว็บไซต์ร้านรับซื้อของเก่าวงษ์พาณิชย์ '
            'และบันทึกลง SQLite เพื่อใช้เป็นราคามาตรฐานทั่วทั้งแอป',
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

class PriceLastUpdatedRow extends StatelessWidget {
  const PriceLastUpdatedRow({required this.lastUpdated, super.key});

  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.history_rounded, color: AppColors.darkGreen, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lastUpdated == null
                ? 'ยังไม่มีการอัปเดต'
                : 'อัปเดตล่าสุด: ${DateFormatter.dateTime(lastUpdated!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class PriceUpdateButton extends StatelessWidget {
  const PriceUpdateButton({
    required this.isUpdating,
    required this.onPressed,
    super.key,
  });

  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isUpdating ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(58),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
      ),
      icon: isUpdating
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.cloud_download_rounded, size: 24),
      label: Text(isUpdating ? 'กำลังอัปเดต...' : 'อัปเดตราคาจากเว็บ'),
    );
  }
}

class PriceErrorBanner extends StatelessWidget {
  const PriceErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PriceCard extends StatelessWidget {
  const PriceCard({required this.price, super.key});

  final MaterialPriceModel price;

  @override
  Widget build(BuildContext context) {
    final bool isLive = price.source == WongpanitPriceService.sourceName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardGreen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.recycling_rounded,
              color: AppColors.primaryGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${price.category} • ${isLive ? 'วงษ์พาณิชย์' : 'ค่าเริ่มต้น'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${NumberFormatter.money(price.pricePerKg)}/กก.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
