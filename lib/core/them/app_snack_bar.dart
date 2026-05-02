import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';

enum SnackType { error, success, warning, info }

class AppSnackBar {
  AppSnackBar._();

  static void show(
    String message, {
    required SnackType type,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final config = _getConfig(type);

    Get.snackbar(
      title ?? config.title,
      message,
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: config.bgColor,
      colorText: config.messageColor,
      margin: const EdgeInsets.all(12),
      borderRadius: 14,
      icon: Icon(
        config.icon,
        color: config.iconColor,
      ),
      borderColor: config.borderColor,
      borderWidth: type == SnackType.info ? 0 : 3,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Shortcuts
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  static void error(String message) =>
      show(message, type: SnackType.error);

  static void success(String message) =>
      show(message, type: SnackType.success);

  static void warning(String message) =>
      show(message, type: SnackType.warning);

  static void info(String message) =>
      show(message, type: SnackType.info);

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Config
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  static _SnackConfig _getConfig(SnackType type) {
    switch (type) {
      case SnackType.error:
        return _SnackConfig(
          title: 'خطأ',
          icon: Icons.close_rounded,
          bgColor: const Color(0xFFFFEBEE),
          borderColor: MyColors.error,
          iconColor: MyColors.error,
          messageColor: const Color(0xFFC62828),
        );

      case SnackType.success:
        return _SnackConfig(
          title: 'نجاح',
          icon: Icons.check_rounded,
          bgColor: const Color(0xFFE8F5E9),
          borderColor: MyColors.success,
          iconColor: MyColors.success,
          messageColor: const Color(0xFF1B5E20),
        );

      case SnackType.warning:
        return _SnackConfig(
          title: 'تحذير',
          icon: Icons.warning_amber_rounded,
          bgColor: const Color(0xFFFFF8E1),
          borderColor: MyColors.warning,
          iconColor: MyColors.warning,
          messageColor: const Color(0xFFE65100),
        );

      case SnackType.info:
        return _SnackConfig(
          title: 'معلومة',
          icon: Icons.info_outline_rounded,
          bgColor: MyColors.primary,
          borderColor: Colors.transparent,
          iconColor: Colors.white,
          messageColor: Colors.white,
        );
    }
  }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// Config Model
// ━━━━━━━━━━━━━━━━━━━━━━━━

class _SnackConfig {
  final String title;
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final Color messageColor;

  const _SnackConfig({
    required this.title,
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.messageColor,
  });
}