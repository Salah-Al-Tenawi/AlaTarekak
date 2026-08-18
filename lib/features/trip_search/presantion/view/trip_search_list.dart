import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/empty_trips_content.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/item_search_trip.dart';

class TripSearchList extends StatefulWidget {
  const TripSearchList({super.key});

  @override
  State<TripSearchList> createState() => _TripSearchListState();
}

class _TripSearchListState extends State<TripSearchList> {
  late final List<TripModel> trips;

  /// النتائج من «رحلات مدينتي» لا من بحث بمعايير.
  bool fromCity = false;

  @override
  void initState() {
    // الشكل الحالي خريطة تحمل المصدر معها؛ والقائمة المجرّدة تُقبل أيضاً
    // لأن الشاشة مسار مسمّى قد يُنادى من مكان آخر.
    final args = Get.arguments;
    if (args is Map) {
      trips = (args['trips'] as List?)?.cast<TripModel>() ?? const [];
      fromCity = args['fromCity'] == true;
    } else {
      trips = (args as List?)?.cast<TripModel>() ?? const [];
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(fromCity ? 'رحلات مدينتك' : 'الرحلات المتاحة'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(36.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(
              fromCity
                  ? '${trips.length} رحلة من مدينتك أو إليها'
                  : '${trips.length} رحلة متاحة',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: MyColors.textOnDark.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
      body: trips.isEmpty
          ? FadeSlideIn(
              // قابل للتمرير: المحتوى مع الاقتراحات لا يسع شاشة قصيرة
              // ولا الوضع الأفقي
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                child: Center(
                  child: EmptyTripsContent(
                    onAdjustSearch: () => Get.back(),
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
              itemCount: trips.length,
              // دخول متدرّج كبقية قوائم التطبيق (رحلاتي، حجوزاتي، الإشعارات)
              itemBuilder: (context, index) => StaggeredItem(
                index: index,
                child: ItemSearchTrip(trip: trips[index]),
              ),
            ),
    );
  }
}
