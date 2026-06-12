import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/them/my_colors.dart';

/// Holds the current theme mode, persists it in Hive, and notifies the
/// app root (main.dart listens via ValueListenableBuilder) to rebuild.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'isDarkMode';

  final ValueNotifier<bool> isDark = ValueNotifier(false);

  /// Call once at startup (after Hive init, before runApp).
  void load() {
    final saved = HiveBoxes.settingsBox.get(_key, defaultValue: false) as bool;
    MyColors.apply(saved);
    isDark.value = saved;
  }

  void setDark(bool dark) {
    if (dark == isDark.value) return;
    MyColors.apply(dark);
    HiveBoxes.settingsBox.put(_key, dark);
    isDark.value = dark;
    // Rebuild the whole widget tree (navigation stack preserved) so every
    // MyColors read re-resolves against the new palette.
    Get.forceAppUpdate();
  }

  void toggle() => setDark(!isDark.value);
}
