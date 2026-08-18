import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';

/// محتوى «لا توجد رحلات» — مصدر واحد للأيقونة والنصّين.
///
/// يظهر في موضعين: حواراً فوق شاشة البحث حين يعود البحث فارغاً، وداخل
/// شاشة النتائج حين تصل قائمة فارغة. توحيدهما هنا يمنع اختلاف الشكل أو
/// النصّ بين الموضعين.
///
/// **بحث فارغ ليس خطأً.** الرحلة قد لا تكون أُنشئت بعد، فالنبرة اقتراح
/// لا اعتذار، والاقتراحات محدّدة: تاريخ آخر، أو موقع أقرب، أو انتظار.
class EmptyTripsContent extends StatelessWidget {
  /// حجم الأيقونة يصغر داخل الحوار ويكبر في الشاشة الكاملة.
  final bool compact;

  /// زرّ «عدّل البحث» — يظهر حيث يملك المستخدم تغيير شيء.
  final VoidCallback? onAdjustSearch;

  /// النتيجة من «رحلات مدينتي» لا من بحث بمعايير.
  ///
  /// «غيّر التاريخ أو الموقع» نصيحة لا معنى لها لمن لم يُدخل تاريخاً ولا
  /// موقعاً — فالاقتراحات تختلف باختلاف ما فعله المستخدم.
  final bool fromCity;

  const EmptyTripsContent({
    super.key,
    this.compact = false,
    this.onAdjustSearch,
    this.fromCity = false,
  });

  /// حدّ أعلى بالبكسل المنطقي: النصّ لا يُقرأ ممتداً على لوح عريض.
  static const double _maxWidth = 380;

  @override
  Widget build(BuildContext context) {
    final circle = compact ? 84.w : 104.w;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SearchHalo(size: circle, compact: compact),
          SizedBox(height: compact ? 18.h : 24.h),
          Text(
            fromCity ? 'لا رحلات في مدينتك الآن' : 'لا توجد رحلات مطابقة',
            style: AppTextStyles.titleMedium,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            fromCity
                ? 'لم يُنشئ أحد رحلة تنطلق من مدينتك أو تتّجه إليها بعد.'
                : 'لم يُنشئ أحد رحلة على هذا المسار في التاريخ الذي اخترته '
                    'بعد.',
            style: AppTextStyles.bodySmall
                .copyWith(color: MyColors.textSecondary, height: 1.7),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: compact ? 16.h : 20.h),
          _Hints(fromCity: fromCity),
          if (onAdjustSearch != null) ...[
            SizedBox(height: 20.h),
            SizedBox(
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: onAdjustSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  // الثيم يفرض عرضاً ممتداً — غير مناسب لزرّ وسط رسالة
                  minimumSize: Size(0, 46.h),
                  padding: EdgeInsets.symmetric(horizontal: 22.w),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r)),
                ),
                icon: Icon(Icons.tune_rounded, size: 18.sp),
                label: const Text('عدّل البحث'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// أيقونة بحث داخل هالة بحلقة خارجية باهتة — عمق بلا صورة إضافية.
class _SearchHalo extends StatelessWidget {
  final double size;
  final bool compact;

  const _SearchHalo({required this.size, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MyColors.primary.withValues(alpha: 0.06),
      ),
      child: Container(
        width: size * 0.72,
        height: size * 0.72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MyColors.primary.withValues(alpha: 0.10),
          border: Border.all(
              color: MyColors.primary.withValues(alpha: 0.20), width: 1.5),
        ),
        child: Icon(
          Icons.travel_explore_rounded,
          size: compact ? 32.sp : 40.sp,
          color: MyColors.primary,
        ),
      ),
    );
  }
}

/// ثلاثة اقتراحات عملية بدل جملة واحدة عامة.
class _Hints extends StatelessWidget {
  final bool fromCity;

  const _Hints({this.fromCity = false});

  static const List<(IconData, String)> _search = [
    (Icons.event_rounded, 'جرّب تاريخاً آخر — الرحلات تُنشأ قبل موعدها بأيام'),
    (Icons.place_outlined, 'وسّع نقطة الانطلاق أو الوجهة إلى مدينة قريبة'),
    (Icons.notifications_none_rounded, 'عاود البحث لاحقاً، تُضاف رحلات يومياً'),
  ];

  /// من لم يُدخل شيئاً لا يُنصح بتغيير ما لم يُدخله.
  static const List<(IconData, String)> _city = [
    (Icons.search_rounded, 'حدّد مساراً وتاريخاً للبحث في مدن أخرى'),
    (Icons.person_pin_circle_outlined,
        'تأكّد أن محافظتك في «حسابي» صحيحة — عليها تُبنى هذه القائمة'),
    (Icons.notifications_none_rounded, 'عاود لاحقاً، تُضاف رحلات يومياً'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = fromCity ? _city : _search;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: MyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(items[i].$1, size: 16.sp, color: MyColors.accent),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    items[i].$2,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: MyColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
