import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/route_manager.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_search/presantion/view/widget/item_search_trip.dart';

class TripSearchList extends StatefulWidget {
  const TripSearchList({super.key});

  @override
  State<TripSearchList> createState() => _TripSearchListState();
}

class _TripSearchListState extends State<TripSearchList> {
  late final List<TripModel> trips;

  @override
  void initState() {
    trips = Get.arguments as List<TripModel>;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      appBar: AppBar(
        backgroundColor: MyColors.primary,
        foregroundColor: MyColors.textOnDark,
        elevation: 0,
        centerTitle: true,
        title: const Text('الرحلات المتاحة'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(36.h),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.only(bottom: 10.h),
            child: Text(
              '${trips.length} رحلة متاحة',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: MyColors.textOnDark.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
      ),
      body: trips.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: EdgeInsets.only(top: 12.h, bottom: 24.h),
              itemCount: trips.length,
              itemBuilder: (context, index) =>
                  ItemSearchTrip(trip: trips[index]),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: MyColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.airport_shuttle_outlined,
                  size: 40, color: MyColors.primary),
            ),
            SizedBox(height: 20.h),
            Text(
              'لا توجد رحلات متاحة حالياً',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'حاول تغيير التاريخ أو الموقع للعثور على رحلات أخرى',
              style: AppTextStyles.bodySmall
                  .copyWith(color: MyColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
