import 'package:flutter/material.dart';

class MyColors {
  MyColors._();

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Brand Colors
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const primary   = Color(0xFF253C5B);
  static const accent    = Color(0xFFED8B10);

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Text Colors
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const textPrimary   = Color(0xFF263238);
  static const textSecondary = Color(0xFF505A63);
  static const textHint      = Color(0xFF95969D);
  static const textLight     = Color(0xFFD9D9D9);
  static const textOnDark    = Color(0xFFFFFFFF); // نص على خلفية داكنة

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Backgrounds
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const background  = Color(0xFFF8F9FA);
  static const surface     = Color(0xFFFFFFFF);
  static const surfaceAlt  = Color(0xFFE0E0E0);
  static const cardBg      = Color(0xFFFFFFFF); // خلفية الكروت

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Borders & Dividers
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const border  = Color(0xFFE5E5E5);
  static const divider = Color(0xFFF1F1F1);

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Status Colors
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const success        = Color(0xFF2E7D32);
  static const successLight   = Color(0xFFE8F5E9); // خلفية badge النجاح
  static const error          = Color(0xFFD32F2F);
  static const errorLight     = Color(0xFFFFEBEE); // خلفية badge الخطأ
  static const warning        = Color(0xFFF9A825);
  static const warningLight   = Color(0xFFFFF8E1);

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Financial (من شاشة المحفظة)
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const income  = Color(0xFF2E7D32); // قيم موجبة +
  static const expense = Color(0xFFD32F2F); // قيم سالبة -

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Shadows
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const shadowLight  = Color(0x0A000000); // 4% opacity
  static const shadowMedium = Color(0x1A000000); // 10% opacity

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Extra Brand Shades
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  static const blue  = Color(0xFF356899);
  static const navy  = Color(0xFF0D1B2A);
  static const cyan  = Color(0xFF5FBBC8);
  static const accentLight = Color(0xFFFFF3E0); // خلفية badge الـ accent
}