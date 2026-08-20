import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:alatarekak/core/them/app_snack_bar.dart';

/// شريط إشعار بسياق — عبر `ScaffoldMessenger`.
///
/// كان يرسم مستطيلاً رمادياً واحداً لكل شيء: «تم إلغاء الحجز» و«فشل
/// التقييم» بلون واحد، فلا يعرف المستخدم أنجح ما فعل أم لا إلا بقراءة
/// النصّ. والتطبيق فيه شريط ملوّن أصلاً ([AppSnackBar])، فبدا الأمر
/// الواحد بشكلين حسب الشاشة.
///
/// الجسم الآن [AppSnackContent] نفسه، و[type] تختار نبرته.
///
/// **بقي على `ScaffoldMessenger`** ولم يُحوّل إلى Get: الشريط هنا يُعرض
/// من داخل شجرة الشاشة، فيختفي معها إن غادرها المستخدم — وهو الصواب
/// لرسالة تخصّ ما كان يفعله فيها.
void showMySnackBar(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
  String? title,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: AppSnackContent(message: message, type: type, title: title),
        // الجسم يرسم خلفيته بنفسه
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        duration: duration,
      ),
    );
}
