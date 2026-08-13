import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// محتوى «لا توجد رحلات» — مصدر واحد للأيقونة والنصّين.
///
/// يظهر في موضعين: حواراً فوق شاشة البحث حين يعود البحث فارغاً، وداخل
/// شاشة النتائج حين تصل قائمة فارغة. توحيدهما هنا يمنع اختلاف الشكل أو
/// النصّ بين الموضعين.
class EmptyTripsContent extends StatelessWidget {
  /// حجم الأيقونة يصغر داخل الحوار ويكبر في الشاشة الكاملة.
  final bool compact;

  const EmptyTripsContent({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final circle = compact ? 72.w : 80.w;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: circle,
          height: circle,
          decoration: BoxDecoration(
            color: MyColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.airport_shuttle_outlined,
            size: compact ? 34.sp : 40.sp,
            color: MyColors.primary,
          ),
        ),
        SizedBox(height: compact ? 16.h : 20.h),
        Text(
          'لا توجد رحلات متاحة حالياً',
          style: AppTextStyles.titleMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8.h),
        Text(
          'حاول تغيير التاريخ أو الموقع للعثور على رحلات أخرى',
          style:
              AppTextStyles.bodySmall.copyWith(color: MyColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
