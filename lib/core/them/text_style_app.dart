import 'package:alatarekak/core/them/my_colors.dart';
import 'package:flutter/material.dart';

/// Getters (not consts) so colors re-resolve when the theme mode changes.
class AppTextStyles {
  AppTextStyles._();

  // Display
  static TextStyle get displayLarge => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: MyColors.textPrimary,
      );

  static TextStyle get displayMedium => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: MyColors.textPrimary,
      );

  // Titles
  static TextStyle get titleLarge => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: MyColors.textPrimary,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: MyColors.textPrimary,
      );

  // Body
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        color: MyColors.textPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        color: MyColors.textPrimary,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        color: MyColors.textSecondary,
      );

  // Labels
  static TextStyle get labelLarge => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: MyColors.primary,
      );

  static TextStyle get labelMedium => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: MyColors.textSecondary,
      );

  static TextStyle get labelSmall => TextStyle(
        fontSize: 11,
        color: MyColors.textHint,
      );

  // Buttons
  static TextStyle get buttonLarge => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  static TextStyle get buttonPrimary => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: MyColors.primary,
      );

  // Accent
  static TextStyle get accent => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: MyColors.accent,
      );
}
