import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_did_you_back.dart';

/// عرض إنشاء رحلة العودة بعد نشر رحلة الذهاب.
///
/// كان العرض سؤالاً بحجم نصّ عادي وزرَّين بخطّين **مختلفين** («نعم» بـ
/// bodySmall و«لا شكراً» بـ bodyMedium) وعرضين ثابتين لا يتجاوبان. صار
/// بطاقةً تشرح ما سيحدث، والزرّان متساويان: الإيجابي ممتلئ والمحيِّد
/// محدَّد بالحدّ لا بالتعبئة.
class TripDidYouBackTextAndButtons extends StatefulWidget {
  final TripFrom tripFrom;

  const TripDidYouBackTextAndButtons({
    super.key,
    required this.tripFrom,
  });

  @override
  State<TripDidYouBackTextAndButtons> createState() =>
      _TripDidYouBackTextAndButtonsState();
}

class _TripDidYouBackTextAndButtonsState
    extends State<TripDidYouBackTextAndButtons> {
  /// يعكس المسار: الوجهة تصبح نقطة الانطلاق والعكس.
  ///
  /// كانت الإحداثيات وحدها تُقلَب دون `startName` و`endName`، فتُنشأ رحلة
  /// العودة بإحداثيات معكوسة وعنوانين **على حالهما** — فيرى السائق والراكب
  /// مساراً مكتوباً يخالف المسار الحقيقي. العناوين تُقلَب هنا معها.
  void _swapSourceAndDestination() {
    final trip = widget.tripFrom;

    final startLat = trip.startLat;
    final startLng = trip.startLng;
    final startName = trip.startName;

    trip.startLat = trip.endLat;
    trip.startLng = trip.endLng;
    trip.startName = trip.endName;

    trip.endLat = startLat;
    trip.endLng = startLng;
    trip.endName = startName;

    trip.reverseTripRoute = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: MyColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
            border:
                Border.all(color: MyColors.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: MyColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.swap_calls_rounded,
                        color: MyColors.primary, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'هل ترغب بإنشاء رحلة للعودة؟',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontSize: 15.sp,
                        color: MyColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Text(
                'سنعكس المسار تلقائياً — تختار الموعد والمقاعد فقط.',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 12.sp,
                  color: MyColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        TripFlowPrimaryButton(
          label: 'نعم، أنشئ رحلة العودة',
          icon: Icons.swap_calls_rounded,
          color: MyColors.primary,
          onTap: () {
            _swapSourceAndDestination();
            Get.toNamed(RouteName.tripSelectDateAndSeats,
                arguments: widget.tripFrom);
          },
        ),
        SizedBox(height: 10.h),
        // إجراء محيِّد: محدَّد بالحدّ لا بالتعبئة فلا ينافس الإجراء الأساسي
        SizedBox(
          width: double.infinity,
          height: 48.h,
          child: OutlinedButton(
            onPressed: () => Get.offAllNamed(RouteName.home),
            style: OutlinedButton.styleFrom(
              foregroundColor: MyColors.textSecondary,
              side: BorderSide(color: MyColors.border, width: 1.2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r)),
            ),
            child: Text(
              'لا شكراً، إلى الرئيسية',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: MyColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
