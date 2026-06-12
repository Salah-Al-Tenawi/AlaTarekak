import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/them/theme_controller.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded,
              color: MyColors.primary, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text("الإعدادات", style: AppTextStyles.titleMedium),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── المظهر ──
          Text('المظهر',
              style:
                  AppTextStyles.labelMedium.copyWith(color: MyColors.textHint)),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: MyColors.surface,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: MyColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ValueListenableBuilder<bool>(
              valueListenable: ThemeController.instance.isDark,
              builder: (context, isDark, _) {
                return SwitchListTile(
                  value: isDark,
                  onChanged: (v) => ThemeController.instance.setDark(v),
                  title: Text('الوضع الليلي', style: AppTextStyles.bodyMedium),
                  subtitle: Text(
                    isDark ? 'مفعّل' : 'متوقف',
                    style: AppTextStyles.bodySmall,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? MyColors.accentLight
                          : MyColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: isDark ? MyColors.accent : MyColors.primary,
                      size: 20,
                    ),
                  ),
                  activeThumbColor: MyColors.accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
