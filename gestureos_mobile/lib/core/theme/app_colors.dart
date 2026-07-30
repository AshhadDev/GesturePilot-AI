import 'package:flutter/material.dart';

/// Centralized color definitions for GestureOS dark theme.
/// All colors follow the premium dark design language.
abstract final class AppColors {
  AppColors._();

  // ── Backgrounds ──
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF111118);
  static const Color card = Color(0xFF17171F);

  // ── Primary Palette ──
  static const Color primary = Color(0xFF7C3AED);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFA855F7);

  // ── Gradient ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient primaryGradientHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [primary, accent],
  );

  // ── Status ──
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);

  // ── Text ──
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA1A1AA);

  // ── Border ──
  static const Color border = Color(0xFF2A2A35);

  // ── Glow ──
  static const Color glowPurple = Color(0x4D7C3AED);
  static const Color glowPurpleStrong = Color(0x807C3AED);

  // ── Overlay ──
  static const Color overlay = Color(0x66000000);
}
