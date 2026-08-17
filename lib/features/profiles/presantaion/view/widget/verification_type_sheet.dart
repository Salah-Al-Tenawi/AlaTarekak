import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// اختيار نوع التوثيق: راكب أو سائق.
///
/// سياسة التطبيق تترك الاختيار للمستخدم في كل مرة. لكن شاشة الحالة كانت
/// تستنتج النوع من **المستندات المرفوعة سابقاً**
/// (`docs?.licensePic != null`) وتُمرّره ثابتاً إلى شاشة الرفع — فمن رُفض
/// طلبه كراكب لا يجد إلا «توثيق كراكب» ولا سبيل له إلى التقديم كسائق،
/// ومن أراد التحوّل من سائق إلى راكب كذلك.
///
/// الاختيار هنا مرة واحدة، ويُفتح من كل موضع يبدأ منه تقديم أو إعادة
/// تقديم.
class VerificationTypeSheet {
  VerificationTypeSheet._();

  /// يفتح الورقة ثم ينتقل إلى شاشة رفع المستندات بالنوع المختار.
  ///
  /// [suggested] النوع المرجَّح من مستندات الطلب السابق — يُبرَز وحده،
  /// ولا يمنع اختيار الآخر.
  static Future<void> show(BuildContext context, {String? suggested}) {
    final suggestDriver = suggested?.toLowerCase() == 'driver';

    return showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      backgroundColor: MyColors.surface,
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                    color: MyColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            SizedBox(height: 20.h),
            Text('نوع التوثيق', style: AppTextStyles.titleLarge),
            SizedBox(height: 6.h),
            Text('اختر نوع التوثيق الذي تريد إتمامه',
                style: AppTextStyles.bodySmall
                    .copyWith(color: MyColors.textSecondary)),
            SizedBox(height: 24.h),
            VerificationTypeOption(
              icon: Icons.person_outline_rounded,
              title: 'توثيق كمستخدم',
              subtitle: 'صورة الهوية الشخصية فقط',
              highlighted: suggested != null && !suggestDriver,
              onTap: () => _go('passenger'),
            ),
            SizedBox(height: 12.h),
            VerificationTypeOption(
              icon: Icons.drive_eta_outlined,
              title: 'توثيق كسائق',
              subtitle: 'الهوية + رخصة القيادة + فحص السيارة',
              highlighted: suggestDriver,
              onTap: () => _go('driver'),
            ),
          ],
        ),
      ),
    );
  }

  static void _go(String type) {
    Get.back(); // أغلق الورقة أولاً وإلا بقيت فوق شاشة الرفع
    Get.toNamed(RouteName.verfiyUser, arguments: type);
  }
}

class VerificationTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// النوع المرجَّح من الطلب السابق — إطار ملوّن لا أكثر، والآخر يبقى
  /// قابلاً للاختيار.
  final bool highlighted;

  const VerificationTypeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: MyColors.background,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: highlighted ? MyColors.primary : MyColors.border,
            width: highlighted ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42.w,
              height: 42.w,
              decoration: BoxDecoration(
                color: MyColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: MyColors.primary, size: 22.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyMedium),
                  SizedBox(height: 2.h),
                  Text(subtitle,
                      style: AppTextStyles.labelSmall
                          .copyWith(color: MyColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: MyColors.textHint),
          ],
        ),
      ),
    );
  }
}
