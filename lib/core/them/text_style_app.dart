import 'package:alatarekak/core/them/my_colors.dart';
import 'package:flutter/material.dart';


class AppTextStyles {
  AppTextStyles._();

  // Display
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: MyColors.textPrimary,
  );

  static const displayMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: MyColors.textPrimary,
  );

  // Titles
  static const titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: MyColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: MyColors.textPrimary,
  );

  // Body
  static const bodyLarge = TextStyle(
    fontSize: 16,
    color: MyColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    color: MyColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    color: MyColors.textSecondary,
  );

  // Labels
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: MyColors.primary,
  );

  static const labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: MyColors.textSecondary,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    color: MyColors.textHint,
  );

  // Buttons
  static const buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const buttonPrimary = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: MyColors.primary,
  );

  // Accent
  static const accent = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: MyColors.accent,
  );
}