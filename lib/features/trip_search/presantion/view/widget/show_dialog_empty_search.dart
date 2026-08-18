import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/empty_trips_content.dart';

/// «لا توجد رحلات» فوق شاشة البحث — يُغلَق ليعود المستخدم إلى معايير بحثه.
///
/// `Dialog` لا `AlertDialog`: الأخير يفرض حشواته وترتيب أزراره، وهنا
/// المحتوى نفسه يحمل زرّه ضمن تصميمه.
Future<void> showNoTripsDialog(BuildContext context,
    {bool fromCity = false}) async {
  return showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: MyColors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        // الوضع الأفقي والشاشات القصيرة: يمرّر بدل أن يفيض
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 26.h, 20.w, 20.h),
            child: EmptyTripsContent(
              compact: true,
              fromCity: fromCity,
              onAdjustSearch: () => Navigator.pop(ctx),
            ),
          ),
        ),
      ),
    ),
  );
}
