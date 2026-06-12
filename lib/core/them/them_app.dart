import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:alatarekak/core/them/my_colors.dart';

/// Getters (not static finals) so ThemeData is rebuilt with the active
/// MyColors palette whenever the app root rebuilds on theme switch.
class ThemApp {
  static ThemeData get lightThem => _build(ThemeData.light(), Brightness.light);
  static ThemeData get darkThem => _build(ThemeData.dark(), Brightness.dark);

  static ThemeData _build(ThemeData base, Brightness brightness) {
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      scaffoldBackgroundColor: MyColors.background,

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // Color Scheme
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(
              primary: MyColors.primary,
              secondary: MyColors.accent,
              surface: MyColors.surface,
              error: MyColors.error,
            )
          : ColorScheme.light(
              primary: MyColors.primary,
              secondary: MyColors.accent,
              surface: MyColors.surface,
              error: MyColors.error,
            ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // AppBar
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      appBarTheme: AppBarTheme(
        backgroundColor: MyColors.surface,
        foregroundColor: MyColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: MyColors.textPrimary,
        ),
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // Bottom Navigation Bar
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: MyColors.primary,
        selectedItemColor: MyColors.accent,
        unselectedItemColor: MyColors.textLight,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // Elevated Button
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // Outlined Button
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MyColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: BorderSide(color: MyColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // Input Fields
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MyColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.cairo(
          color: MyColors.textHint,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyColors.error),
        ),
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // Card
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      cardTheme: CardThemeData(
        color: MyColors.surface,
        elevation: 2,
        shadowColor: MyColors.shadowLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━
      // Divider
      // ━━━━━━━━━━━━━━━━━━━━━━━━
      dividerTheme: DividerThemeData(
        color: MyColors.divider,
        thickness: 1,
        space: 0,
      ),
    );
  }
}
