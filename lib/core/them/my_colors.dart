import 'package:flutter/material.dart';

/// All color values for one theme mode.
class _Palette {
  final Color primary, accent;
  final Color textPrimary, textSecondary, textHint, textLight, textOnDark;
  final Color background, surface, surfaceAlt, cardBg;
  final Color border, divider;
  final Color success, successLight, error, errorLight, warning, warningLight;
  final Color income, expense;
  final Color shadowLight, shadowMedium;
  final Color blue, navy, cyan, accentLight;

  const _Palette({
    required this.primary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.textLight,
    required this.textOnDark,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.cardBg,
    required this.border,
    required this.divider,
    required this.success,
    required this.successLight,
    required this.error,
    required this.errorLight,
    required this.warning,
    required this.warningLight,
    required this.income,
    required this.expense,
    required this.shadowLight,
    required this.shadowMedium,
    required this.blue,
    required this.navy,
    required this.cyan,
    required this.accentLight,
  });
}

const _light = _Palette(
  // Brand
  primary: Color(0xFF253C5B),
  accent: Color(0xFFED8B10),
  // Text
  textPrimary: Color(0xFF263238),
  textSecondary: Color(0xFF505A63),
  textHint: Color(0xFF95969D),
  textLight: Color(0xFFD9D9D9),
  textOnDark: Color(0xFFFFFFFF),
  // Backgrounds
  background: Color(0xFFF8F9FA),
  surface: Color(0xFFFFFFFF),
  surfaceAlt: Color(0xFFE0E0E0),
  cardBg: Color(0xFFFFFFFF),
  // Borders & dividers
  border: Color(0xFFE5E5E5),
  divider: Color(0xFFF1F1F1),
  // Status
  success: Color(0xFF2E7D32),
  successLight: Color(0xFFE8F5E9),
  error: Color(0xFFD32F2F),
  errorLight: Color(0xFFFFEBEE),
  warning: Color(0xFFF9A825),
  warningLight: Color(0xFFFFF8E1),
  // Financial
  income: Color(0xFF2E7D32),
  expense: Color(0xFFD32F2F),
  // Shadows
  shadowLight: Color(0x0A000000),
  shadowMedium: Color(0x1A000000),
  // Extra brand shades
  blue: Color(0xFF356899),
  navy: Color(0xFF0D1B2A),
  cyan: Color(0xFF5FBBC8),
  accentLight: Color(0xFFFFF3E0),
);

/// Navy-tinted dark palette: keeps the brand identity (navy + orange)
/// instead of flat grays.
const _dark = _Palette(
  // Brand — primary is lightened so it stays readable as both a
  // background and an icon/text color on dark surfaces.
  primary: Color(0xFF4A6FA0),
  accent: Color(0xFFED8B10),
  // Text
  textPrimary: Color(0xFFE8EAED),
  textSecondary: Color(0xFFB3BAC3),
  textHint: Color(0xFF7E8590),
  textLight: Color(0xFFAEB6C2),
  textOnDark: Color(0xFFFFFFFF),
  // Backgrounds
  background: Color(0xFF0F1620),
  surface: Color(0xFF1A2332),
  surfaceAlt: Color(0xFF2A3547),
  cardBg: Color(0xFF1A2332),
  // Borders & dividers
  border: Color(0xFF2C3850),
  divider: Color(0xFF1F2A3D),
  // Status — brighter fills, dark-tinted badge backgrounds
  success: Color(0xFF66BB6A),
  successLight: Color(0xFF15281A),
  error: Color(0xFFEF5350),
  errorLight: Color(0xFF2E191B),
  warning: Color(0xFFFFB300),
  warningLight: Color(0xFF2E2712),
  // Financial
  income: Color(0xFF66BB6A),
  expense: Color(0xFFEF5350),
  // Shadows — stronger so cards still separate from the background
  shadowLight: Color(0x40000000),
  shadowMedium: Color(0x66000000),
  // Extra brand shades
  blue: Color(0xFF5E8BC0),
  navy: Color(0xFF0D1B2A),
  cyan: Color(0xFF5FBBC8),
  accentLight: Color(0xFF2F230E),
);

/// App-wide color tokens. Reads from the active palette, so every
/// `MyColors.x` reference across the app follows the current theme mode.
/// Switch with [apply]; the app root rebuilds via ThemeController.
class MyColors {
  MyColors._();

  static _Palette _c = _light;
  static bool get isDark => identical(_c, _dark);
  static void apply(bool dark) => _c = dark ? _dark : _light;

  // ━━ Brand ━━
  static Color get primary => _c.primary;
  static Color get accent => _c.accent;

  // ━━ Text ━━
  static Color get textPrimary => _c.textPrimary;
  static Color get textSecondary => _c.textSecondary;
  static Color get textHint => _c.textHint;
  static Color get textLight => _c.textLight;
  static Color get textOnDark => _c.textOnDark;

  // ━━ Backgrounds ━━
  static Color get background => _c.background;
  static Color get surface => _c.surface;
  static Color get surfaceAlt => _c.surfaceAlt;
  static Color get cardBg => _c.cardBg;

  // ━━ Borders & Dividers ━━
  static Color get border => _c.border;
  static Color get divider => _c.divider;

  // ━━ Status ━━
  static Color get success => _c.success;
  static Color get successLight => _c.successLight;
  static Color get error => _c.error;
  static Color get errorLight => _c.errorLight;
  static Color get warning => _c.warning;
  static Color get warningLight => _c.warningLight;

  // ━━ Financial ━━
  static Color get income => _c.income;
  static Color get expense => _c.expense;

  // ━━ Shadows ━━
  static Color get shadowLight => _c.shadowLight;
  static Color get shadowMedium => _c.shadowMedium;

  // ━━ Extra Brand Shades ━━
  static Color get blue => _c.blue;
  static Color get navy => _c.navy;
  static Color get cyan => _c.cyan;
  static Color get accentLight => _c.accentLight;
}
