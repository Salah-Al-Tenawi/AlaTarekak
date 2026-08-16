import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

class ItemTrip extends StatelessWidget {
  final TripModel trip;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const ItemTrip({
    super.key,
    required this.trip,
    this.onTap,
    this.onCancel,
  });

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
        borderRadius: radius,
        onTap: onTap,
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
                    child: Text(
                      trip.driver.name.isEmpty ? 'رحلتي' : trip.driver.name,
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

              // ━━ الموعد ━━
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
                      // `available_seats` هي المقاعد المتبقّية لا الإجمالي،
                      // فصياغة «س من ص» تصف شيئاً لا يرسله الخادم.
                      // والصفر يُصاغ نفياً صريحاً: «مقاعد متاحة» وحدها كانت
                      // تُقرأ إثباتاً على رحلة ممتلئة.
                      label: _seatsLabel(trip.seatsAvailable),
                      color: trip.seatsAvailable > 0
                          ? MyColors.success
                          : MyColors.textSecondary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8.h),

              // ━━ الحجوزات والمسار ━━
              // `bookings_count` يصل في قائمة الرحلات ولم يكن يُعرض، وهو
              // أول ما يبحث عنه السائق في رحلته. والمسافة والمدّة تصلان
              // معه فتُعرضان بدل أن تُهدرا.
              Row(
                children: [
                  Expanded(
                    child: TripInfoChip(
                      expand: true,
                      icon: Icons.people_alt_rounded,
                      label: _bookingsLabel(trip.bookingsCount),
                      color: trip.bookingsCount > 0
                          ? MyColors.primary
                          : MyColors.textSecondary,
                    ),
                  ),
                  if (trip.distance.meters > 0) ...[
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TripInfoChip(
                        expand: true,
                        icon: Icons.route_rounded,
                        label: _routeLabel(
                            trip.distance.kilometers, trip.duration.minutes),
                        color: MyColors.blue,
                      ),
                    ),
                  ],
                ],
              ),

              if (trip.driver.id == myid()) _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// إجراءات السائق على رحلته.
  ///
  /// كان زرّ الإلغاء يملأ عرض البطاقة بارتفاع كبير فيطغى على محتواها كلّه،
  /// وهو إجراء هدّام لا يُبرَّر إبرازه هكذا. صار الإجراء الأساسي (العدّ
  /// التنازلي أو إنهاء الرحلة) هو الممتدّ، والإلغاء زرّاً محدَّداً بحجمه
  /// إلى جانبه.
  Widget _buildActions(BuildContext context) {
    final remaining = trip.departure.difference(DateTime.now());
    final departed = remaining.inSeconds <= 0;

    final canCancel = trip.status == 'active' && !departed;
    final canFinish = departed &&
        trip.status != 'finished' &&
        trip.status != 'awaiting_confirmation' &&
        trip.status != 'cancelled';

    if (!canCancel && !canFinish) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: Row(
        children: [
          Expanded(
            child: canFinish
                ? _FinishButton(tripId: trip.id)
                : _CountdownChip(remaining: remaining),
          ),
          if (canCancel) ...[
            SizedBox(width: 10.w),
            _CancelButton(onCancel: onCancel),
          ],
        ],
      ),
    );
  }
}

/// العدّ التنازلي حتى الانطلاق — معلومة لا زرّ، فلا تُصاغ كزرّ.
class _CountdownChip extends StatelessWidget {
  final Duration remaining;
  const _CountdownChip({required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: MyColors.warningLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: MyColors.warning.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, color: MyColors.warning, size: 16.sp),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              formatRemainingTime(remaining),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: MyColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishButton extends StatelessWidget {
  final int tripId;
  const _FinishButton({required this.tripId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: ElevatedButton.icon(
        onPressed: () =>
            Get.toNamed(RouteName.tripDetails, arguments: tripId),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Icon(Icons.flag_rounded, size: 16.sp),
        label: Text(
          'إنهاء الرحلة',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// إجراء هدّام: يُعرَض محدَّداً ومحدَّد اللون بالحدّ لا بالتعبئة، فلا يُضغط
/// سهواً ولا يسحب انتباه البطاقة إليه.
class _CancelButton extends StatelessWidget {
  final VoidCallback? onCancel;
  const _CancelButton({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.h,
      child: OutlinedButton.icon(
        onPressed: onCancel,
        style: OutlinedButton.styleFrom(
          foregroundColor: MyColors.error,
          side: BorderSide(
              color: MyColors.error.withValues(alpha: 0.5), width: 1.2),
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        icon: Icon(Icons.close_rounded, size: 16.sp),
        label: Text(
          'إلغاء',
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ─── صياغة نصوص البطاقة ───────────────────────────────────────────────────────
//
// العربية تُثنّي وتجمع بصيغ مختلفة، و«1 مقاعد» أو «2 حجوزات» يقرأها
// المستخدم خطأً في التطبيق لا في بياناته. المفرد والمثنّى يُصاغان صراحةً.

String _seatsLabel(int available) {
  if (available <= 0) return 'لا مقاعد متاحة';
  if (available == 1) return 'مقعد واحد متاح';
  if (available == 2) return 'مقعدان متاحان';
  return '$available مقاعد متاحة';
}

String _bookingsLabel(int count) {
  if (count <= 0) return 'لا حجوزات';
  if (count == 1) return 'حجز واحد';
  if (count == 2) return 'حجزان';
  return '$count حجوزات';
}

/// «47.8 كم · 41 د» — والمدّة الطويلة بالساعات فلا تُقرأ «150 د».
String _routeLabel(double kilometers, int minutes) {
  final distance = kilometers >= 10
      ? '${kilometers.round()} كم'
      : '${kilometers.toStringAsFixed(1)} كم';

  if (minutes < 60) return '$distance · $minutes د';

  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0
      ? '$distance · $hours س'
      : '$distance · $hours س $rest د';
}

String formatRemainingTime(Duration duration) {
  if (duration.inDays > 0) {
    return 'متبقٍ ${duration.inDays} يوم و${duration.inHours % 24} ساعة';
  } else if (duration.inHours > 0) {
    return 'متبقٍ ${duration.inHours} ساعة و${duration.inMinutes % 60} دقيقة';
  } else if (duration.inMinutes > 0) {
    return 'متبقٍ ${duration.inMinutes} دقيقة';
  } else {
    return 'حان موعد الانطلاق';
  }
}
