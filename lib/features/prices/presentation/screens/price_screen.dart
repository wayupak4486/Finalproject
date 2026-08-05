import 'package:flutter/material.dart';

import '../../../../core/constants/material_catalog.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../services/database/app_database.dart';
import '../../../../services/price_source/wongpanit_price_service.dart';
import '../../data/models/material_price_model.dart';
import '../../data/repositories/material_price_repository.dart';
import '../../data/services/price_update_service.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

  static const Color background = Color(0xFFF7FAF3);
  static const Color primaryGreen = Color(0xFF2F7D3A);
  static const Color darkGreen = Color(0xFF1F4F28);
  static const Color cardGreen = Color(0xFFE4ECE0);
  static const Color textDark = Color(0xFF1E211D);
  static const Color textMuted = Color(0xFF5E665B);

  @override
  State<PriceScreen> createState() => _PriceScreenState();
}

class _PriceScreenState extends State<PriceScreen> {
  late final MaterialPriceRepository _priceRepository;
  late final PriceUpdateService _priceUpdateService;

  List<MaterialPriceModel> _prices = [];
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  DateTime? get _lastUpdated {
    if (_prices.isEmpty) return null;

    return _prices
        .map((price) => price.updatedAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  void initState() {
    super.initState();

    _priceRepository = MaterialPriceRepository(database: AppDatabase.instance);
    _priceUpdateService = PriceUpdateService(priceRepository: _priceRepository);

    _loadPrices();
  }

  Future<void> _loadPrices() async {
    try {
      final prices = await _priceRepository.getAllPrices();

      if (!mounted) return;

      setState(() {
        _prices = prices;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrices() async {
    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final result = await _priceUpdateService.updateFromWeb();
      await _loadPrices();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'อัปเดตราคาแล้ว ${result.updatedCount}/${result.totalLabels} รายการจากเว็บ',
          ),
        ),
      );
    } on PriceFetchException catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดขณะอัปเดตราคา';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PriceScreen.background,
      appBar: AppBar(
        backgroundColor: PriceScreen.background,
        elevation: 0,
        title: Text(
          'ราคารับซื้อ',
          style: TextStyle(
            color: PriceScreen.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: PriceScreen.textDark),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPrices,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    const _HeaderCard(),
                    const SizedBox(height: 18),
                    _LastUpdatedRow(lastUpdated: _lastUpdated),
                    const SizedBox(height: 14),
                    _UpdateButton(
                      isUpdating: _isUpdating,
                      onPressed: _updatePrices,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: 26),
                    for (final price in _prices.where(
                      (price) => MaterialCatalog.lookup(price.label).isSellable,
                    )) ...[
                      _PriceCard(price: price),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PriceScreen.cardGreen,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ตารางราคารับซื้อวัสดุรีไซเคิล',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: PriceScreen.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'แอปดึงรายการราคารับซื้อล่าสุดจากเว็บไซต์ร้านรับซื้อของเก่าวงษ์พาณิชย์ '
            'และบันทึกลง SQLite เพื่อใช้เป็นราคามาตรฐานทั่วทั้งแอป',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PriceScreen.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LastUpdatedRow extends StatelessWidget {
  const _LastUpdatedRow({required this.lastUpdated});

  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.history_rounded,
          color: PriceScreen.darkGreen,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            lastUpdated == null
                ? 'ยังไม่มีการอัปเดต'
                : 'อัปเดตล่าสุด: ${DateFormatter.dateTime(lastUpdated!)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: PriceScreen.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.isUpdating, required this.onPressed});

  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isUpdating ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: PriceScreen.primaryGreen,
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

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

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

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});

  final MaterialPriceModel price;

  @override
  Widget build(BuildContext context) {
    final bool isLive = price.source == WongpanitPriceService.sourceName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PriceScreen.cardGreen,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
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
              color: PriceScreen.primaryGreen,
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
                    color: PriceScreen.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${price.category} • ${isLive ? 'วงษ์พาณิชย์' : 'ค่าเริ่มต้น'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PriceScreen.textMuted,
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
              color: PriceScreen.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}
