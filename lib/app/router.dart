import 'package:flutter/material.dart';

import '../features/history/presentation/screens/history_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/prices/presentation/screens/price_screen.dart';
import '../features/scan/presentation/screens/result_screen.dart';
import '../features/scan/presentation/screens/scan_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/statistics/presentation/screens/statistics_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String scan = '/scan';
  static const String result = '/result';
  static const String history = '/history';
  static const String statistics = '/statistics';
  static const String settings = '/settings';
  static const String prices = '/prices';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomeScreen(),
    scan: (_) => const ScanScreen(),
    result: (_) => const ResultScreen(),
    history: (_) => const HistoryScreen(),
    statistics: (_) => const StatisticsScreen(),
    settings: (_) => const SettingsScreen(),
    prices: (_) => const PriceScreen(),
  };
}
