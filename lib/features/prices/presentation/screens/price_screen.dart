import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/material_catalog.dart';
import '../../../../services/database/app_database.dart';
import '../../../../services/price_source/wongpanit_price_service.dart';
import '../../data/models/material_price_model.dart';
import '../../data/repositories/material_price_repository.dart';
import '../../data/services/price_update_service.dart';
import '../widgets/price_screen_widgets.dart';

class PriceScreen extends StatefulWidget {
  const PriceScreen({super.key});

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

  // Data fetching

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

  // Event handlers

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'ราคารับซื้อ',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadPrices,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    const PriceHeaderCard(),
                    const SizedBox(height: 18),
                    PriceLastUpdatedRow(lastUpdated: _lastUpdated),
                    const SizedBox(height: 14),
                    PriceUpdateButton(
                      isUpdating: _isUpdating,
                      onPressed: _updatePrices,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      PriceErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: 26),
                    for (final price in _prices.where(
                      (price) => MaterialCatalog.lookup(price.label).isSellable,
                    )) ...[PriceCard(price: price), const SizedBox(height: 14)],
                  ],
                ),
        ),
      ),
    );
  }
}
