import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// موافقة صريحة على السياسات قبل إنشاء الحساب.
///
/// غير مؤشَّر افتراضياً ويُعطّل زرّ الإنشاء حتى يؤشّره المستخدم: الموافقة
/// الضمنية لا تكفي هنا لأن التسجيل يفتح محفظة مالية على رقم هاتفه.
class PolicyConsentCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  /// يظهر تنبيه أحمر بعد محاولة إنشاء حساب بلا موافقة.
  final bool showError;

  const PolicyConsentCheck({
    super.key,
    required this.value,
    required this.onChanged,
    this.showError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: MyColors.primary,
                side: BorderSide(
                  color: showError ? MyColors.error : MyColors.textHint,
                  width: 1.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5.r),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Text.rich(
                  TextSpan(
                    style: AppTextStyles.bodySmall
                        .copyWith(color: MyColors.textSecondary, height: 1.6),
                    children: [
                      const TextSpan(text: 'قرأت وأوافق على '),
                      TextSpan(
                        text: 'سياسة الخصوصية',
                        style: TextStyle(
                          color: MyColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _open(0),
                      ),
                      const TextSpan(text: ' و'),
                      TextSpan(
                        text: 'سياسة الإلغاء',
                        style: TextStyle(
                          color: MyColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: _open(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showError)
          Padding(
            padding: EdgeInsets.only(top: 6.h, right: 34.w),
            child: Text(
              'يجب الموافقة على السياسات لإنشاء الحساب',
              style: AppTextStyles.labelSmall.copyWith(color: MyColors.error),
            ),
          ),
      ],
    );
  }

  /// فتح الشاشة على التبويب المطلوب (0 خصوصية، 1 إلغاء).
  TapGestureRecognizer _open(int tab) => TapGestureRecognizer()
    ..onTap = () => Get.toNamed(RouteName.policy, arguments: tab);
}
