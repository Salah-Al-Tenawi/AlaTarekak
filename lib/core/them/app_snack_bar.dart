import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// نبرة الشريط — تحدّد لونه وأيقونته.
enum SnackType { error, success, warning, info }

/// شريط إشعار بهوية التطبيق.
///
/// كان لوناً مصمتاً بحدّ من ثلاثة بكسلات حول الشريط كلّه، بألوان مكتوبة
/// رقماً (`0xFFFFEBEE`) لا تعرف الوضع الليلي: في الظلام يظهر مستطيل
/// ورديّ فاقع بنصّ أحمر داكن، بينما للتطبيق لوحة ليلية كاملة لا يمرّ
/// عليها. وكان يعلو كلَّ رسالة عنوانٌ عامّ — «نجاح» فوق «تم إلغاء
/// الحجز» تكرارٌ يزاحم الرسالة نفسها.
///
/// الشكل الآن كحوار التطبيق: أيقونة في هالة من لونها، وشريط لوني رفيع
/// على الحافة بدل إطار يحيط بالكل، وألوان من [MyColors] فتتبع الوضعين.
///
/// وآليتان تعرضانه: [AppSnackBar] بلا سياق عبر Get، و[showMySnackBar]
/// بسياق عبر `ScaffoldMessenger` — والجسم [AppSnackContent] واحد، فلا
/// يظهر في التطبيق شريطان مختلفان لأمرٍ واحد.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    String message, {
    required SnackType type,

    /// عنوان فوق الرسالة. **يُترك فارغاً في الغالب**: الرسالة تقول ما
    /// حدث، والعنوان العامّ يكرّرها. يُذكر حين يضيف معنىً.
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.showSnackbar(GetSnackBar(
      messageText: AppSnackContent(
        message: message,
        type: type,
        title: title,
      ),
      duration: duration,
      snackPosition: SnackPosition.BOTTOM,
      // الجسم يرسم خلفيته وحوافه بنفسه — والحاوية شفافة بلا حشو
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      borderRadius: 0,
      barBlur: 0,
      overlayBlur: 0,
      boxShadows: [
        BoxShadow(
          color: MyColors.shadowMedium,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ));
  }

  static void error(String message, {String? title}) =>
      show(message, type: SnackType.error, title: title);

  static void success(String message, {String? title}) =>
      show(message, type: SnackType.success, title: title);

  static void warning(String message, {String? title}) =>
      show(message, type: SnackType.warning, title: title);

  static void info(String message, {String? title}) =>
      show(message, type: SnackType.info, title: title);
}

/// جسم الشريط — يُرسم كما هو أياً كانت آلية العرض.
class AppSnackContent extends StatelessWidget {
  final String message;
  final SnackType type;
  final String? title;

  const AppSnackContent({
    super.key,
    required this.message,
    required this.type,
    this.title,
  });

  Color get _color => switch (type) {
        SnackType.error => MyColors.error,
        SnackType.success => MyColors.success,
        SnackType.warning => MyColors.warning,
        SnackType.info => MyColors.primary,
      };

  /// خلفية من اللوحة لا رقماً مكتوباً — فتتبع الوضع الليلي من تلقائها.
  Color get _background => switch (type) {
        SnackType.error => MyColors.errorLight,
        SnackType.success => MyColors.successLight,
        SnackType.warning => MyColors.warningLight,
        SnackType.info => MyColors.surface,
      };

  IconData get _icon => switch (type) {
        SnackType.error => Icons.error_outline_rounded,
        SnackType.success => Icons.check_circle_outline_rounded,
        SnackType.warning => Icons.warning_amber_rounded,
        SnackType.info => Icons.info_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16.r);

    return Container(
      decoration: BoxDecoration(
        color: _background,
        borderRadius: radius,
        border: Border.all(color: _color.withValues(alpha: 0.30), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط لوني على حافة البداية — يُقرأ النوع منه بطرف العين،
            // وأخفّ من إطار يحيط بالشريط كلّه
            Container(width: 4.w, color: _color),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32.w,
                      height: 32.w,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon, size: 18.sp, color: _color),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null && title!.trim().isNotEmpty) ...[
                            Text(
                              title!,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.bold,
                                color: _color,
                              ),
                            ),
                            SizedBox(height: 3.h),
                          ],
                          Text(
                            message,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 13.sp,
                              height: 1.45,
                              color: MyColors.textPrimary,
                            ),
                            // رسائل الخادم المعرّبة تطول أحياناً — تُقصّ
                            // بعد أربعة أسطر بدل أن تملأ الشاشة
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
