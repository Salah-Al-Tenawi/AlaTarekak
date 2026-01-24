import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class ThemApp {
  static ThemeData lightThem = ThemeData.light();

  static ThemeData darkThem = ThemeData.dark();
}

// final ThemeData lightTheme = ThemeData(
//   brightness: Brightness.light,

//   // الألوان الأساسية
//   primaryColor: MyColors.navyBlue,
//   scaffoldBackgroundColor: MyColors.lightBeige,
//   canvasColor: MyColors.beige,

//   // اللون المستخدم للـ AppBar وغيره
//   appBarTheme: AppBarTheme(
//     backgroundColor: MyColors.navyBlue,
//     foregroundColor: MyColors.beige,
//     elevation: 0,
//     iconTheme: IconThemeData(color: MyColors.beige),
//     titleTextStyle: TextStyle(
//       color: MyColors.beige,
//       fontSize: 20,
//       fontWeight: FontWeight.bold,
//     ),
//   ),

//   // ألوان النصوص
//   textTheme: TextTheme(
//     bodyLarge: TextStyle(color: MyColors.blackColor),
//     bodyMedium: TextStyle(color: MyColors.greyTextColor),
//     titleLarge: TextStyle(
//       color: MyColors.navyBlue,
//       fontSize: 24,
//       fontWeight: FontWeight.bold,
//     ),
//   ),

//   // ألوان الأزرار
//   elevatedButtonTheme: ElevatedButtonThemeData(
//     style: ElevatedButton.styleFrom(
//       backgroundColor: MyColors.forestGreen,
//       foregroundColor: MyColors.beige,
//       textStyle: const TextStyle(fontWeight: FontWeight.bold),
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//     ),
//   ),

//   // حقول الإدخال
//   inputDecorationTheme: InputDecorationTheme(
//     filled: true,
//     fillColor: MyColors.greyTextField,
//     border: OutlineInputBorder(
//       borderRadius: BorderRadius.circular(10),
//       borderSide: BorderSide.none,
//     ),
//     hintStyle: TextStyle(color: MyColors.greyTextColor),
//   ),

//   // أيقونات
//   iconTheme: IconThemeData(color: MyColors.prussianBlue),

//   // عناصر أخرى
//   dividerColor: MyColors.greyTextColor.withOpacity(0.4),
// );
