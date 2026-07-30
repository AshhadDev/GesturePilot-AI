import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color background = Color(0xFF050505);
  static const Color surface = Color(0xFF0A0A0A);
  static const Color card = Color(0xFF111111);
  static const Color cardHover = Color(0xFF161616);
  static const Color border = Color(0xFF1E1E1E);
  static const Color borderLight = Color(0xFF2A2A2A);

  static const Color primary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFFA855F7);
  static const Color accentLight = Color(0xFFC084FC);

  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textTertiary = Color(0xFF555555);

  static const Color overlay = Color(0x80000000);
  static const Color shimmer = Color(0xFF1A1A1A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, accent],
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surface, background],
  );

  static const RadialGradient orbGlow = RadialGradient(
    colors: [
      Color(0x407C3AED),
      Color(0x20A855F7),
      Colors.transparent,
    ],
  );
}
