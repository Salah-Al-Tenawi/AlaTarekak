import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/status_trip.dart';

class ItemSearchTrip extends StatelessWidget {
  final TripModel trip;
  const ItemSearchTrip({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final statusInfo = getStatusInfo(trip.status);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: MyColors.border, width: 1),
      ),
      elevation: 3,
      shadowColor: MyColors.shadowMedium,
      color: MyColors.surface,
      child: InkWell(
        onTap: () => Get.toNamed(RouteName.tripDetails, arguments: trip.id),
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ━━ رأس البطاقة: السائق + الحالة ━━
              Row(
                children: [
                  _DriverAvatar(avatar: trip.driver.avatar),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      trip.driver.name,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: statusInfo.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      statusInfo.text,
                      style: TextStyle(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 14.h),

              // ━━ خط فاصل ━━
              Divider(height: 1, color: MyColors.divider),

              SizedBox(height: 14.h),

              // ━━ المسار ━━
              _LocationLine(
                icon: Icons.circle,
                iconColor: MyColors.primary,
                text: trip.pickup.address,
              ),
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Container(
                  width: 2,
                  height: 18.h,
                  margin: EdgeInsets.symmetric(vertical: 4.h),
                  color: MyColors.border,
                ),
              ),
              _LocationLine(
                icon: Icons.location_pin,
                iconColor: MyColors.accent,
                text: trip.destination.address,
              ),

              SizedBox(height: 14.h),

              // ━━ التاريخ والوقت ━━
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.calendar_today_rounded,
                    label: DateTimeUtils.formatDate(trip.departure),
                    color: MyColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  _InfoChip(
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
                    child: _InfoChip(
                      icon: Icons.monetization_on_rounded,
                      label: '${trip.pricePerSeat} ل.س / راكب',
                      color: MyColors.warning,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.event_seat_rounded,
                      label: '${trip.seatsAvailable} مقاعد متاحة',
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

class _DriverAvatar extends StatelessWidget {
  final String? avatar;
  const _DriverAvatar({required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42.w,
      height: 42.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: MyColors.primary.withValues(alpha: 0.25),
          width: 2,
        ),
        image: avatar != null
            ? DecorationImage(
                image: NetworkImage(avatar!),
                fit: BoxFit.cover,
              )
            : null,
        color: MyColors.primary.withValues(alpha: 0.08),
      ),
      child: avatar == null
          ? Icon(Icons.person_rounded, color: MyColors.primary, size: 20)
          : null,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: color,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationLine extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _LocationLine(
      {required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall
                .copyWith(color: MyColors.textPrimary, fontSize: 13.sp),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
