import 'package:flutter/material.dart';

/// Shared palette for the app's custom "soft green" screens (home, prices,
/// history, statistics, settings). Centralized here because the same hex
/// values were previously copy-pasted as private constants on every screen.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFF7FAF3);
  static const Color primaryGreen = Color(0xFF2F7D3A);
  static const Color darkGreen = Color(0xFF1F4F28);
  static const Color cardGreen = Color(0xFFE4ECE0);
  static const Color textDark = Color(0xFF1E211D);
  static const Color textMuted = Color(0xFF5E665B);
  static const Color textMutedSecondary = Color(0xFF4F594C);

  /// Faint white border drawn around most cards on the soft-green screens.
  static Color get cardBorder => Colors.white.withValues(alpha: 0.55);
}
