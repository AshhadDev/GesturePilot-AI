import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:gesture_os/core/theme/app_colors.dart';

/// Text style definitions for GestureOS.
/// Uses Poppins font family with proper hierarchy.
abstract final class AppTextStyles {
  AppTextStyles._();

  static TextStyle get _basePoppins => GoogleFonts.poppins();

  // ── Display ──
  static TextStyle get displayLarge => _basePoppins.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: -1.5,
        height: 1.2,
      );

  static TextStyle get displayMedium => _basePoppins.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
        height: 1.25,
      );

  static TextStyle get displaySmall => _basePoppins.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      );

  // ── Headings ──
  static TextStyle get headingLarge => _basePoppins.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      );

  static TextStyle get headingMedium => _basePoppins.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
        height: 1.4,
      );

  static TextStyle get headingSmall => _basePoppins.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.4,
      );

  // ── Body ──
  static TextStyle get bodyLarge => _basePoppins.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        letterSpacing: 0,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _basePoppins.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0,
        height: 1.5,
      );

  static TextStyle get bodySmall => _basePoppins.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
        height: 1.5,
      );

  // ── Labels / Buttons ──
  static TextStyle get labelLarge => _basePoppins.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.4,
      );

  static TextStyle get labelMedium => _basePoppins.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 0.2,
        height: 1.4,
      );

  static TextStyle get labelSmall => _basePoppins.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
        height: 1.4,
      );
}
