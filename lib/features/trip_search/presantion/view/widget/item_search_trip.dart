import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

class ItemSearchTrip extends StatelessWidget {
  final TripModel trip;
  const ItemSearchTrip({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: MyColors.border, width: 1),
      ),
      elevation: 3,
      shadowColor: MyColors.shadowMedium,
      color: MyColors.surface,
      child: InkWell(
        onTap: () => Get.toNamed(RouteName.tripDetails, arguments: trip.id),
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ━━ رأس البطاقة: السائق + الحالة ━━
              Row(
                children: [
                  TripAvatar(avatar: trip.driver.avatar),
                  SizedBox(width: 12.w),
                  Expanded(
                    // مسار البحث يرسل `driver_id` بلا كائن سائق، فيصل
                    // الاسم فارغاً ويظهر سطر خالٍ. البديل تسمية عامة إلى
                    // أن يرسل الخادم الكائن.
                    child: Text(
                      trip.driver.name.trim().isEmpty
                          ? 'سائق الرحلة'
                          : trip.driver.name,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  TripStatusBadge(status: trip.status),
                ],
              ),

              SizedBox(height: 14.h),
              Divider(height: 1, color: MyColors.divider),
              SizedBox(height: 14.h),

              // ━━ المسار ━━
              TripLocationLine(
                icon: Icons.circle,
                iconColor: MyColors.primary,
                text: trip.pickup.address,
              ),
              const TripRouteConnector(),
              TripLocationLine(
                icon: Icons.location_pin,
                iconColor: MyColors.accent,
                text: trip.destination.address,
              ),

              SizedBox(height: 14.h),

              // ━━ التاريخ والوقت ━━
              Row(
                children: [
                  TripInfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateTimeUtils.formatDate(trip.departure),
                    color: MyColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  TripInfoChip(
                    icon: Icons.access_time_rounded,
                    label: DateTimeUtils.formatTime(trip.departure),
                    color: MyColors.accent,
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // ━━ السعر والمقاعد ━━
              Row(
                children: [
                  Expanded(
                    child: TripInfoChip(
                      expand: true,
                      icon: Icons.monetization_on_rounded,
                      label: '${Money.withCurrency(trip.pricePerSeat)} / راكب',
                      color: MyColors.warning,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TripInfoChip(
                      expand: true,
                      icon: Icons.event_seat_rounded,
                      // صفر هنا قد يعني «لم يصل العدّاد» لا «ممتلئة»،
                      // فلا يُعرض رقم يوحي بغير الحقيقة
                      label: trip.seatsAvailable > 0
                          ? '${trip.seatsAvailable} مقاعد متاحة'
                          : 'مقاعد متاحة',
                      color: MyColors.success,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
