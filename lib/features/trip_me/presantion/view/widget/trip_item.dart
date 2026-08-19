import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
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
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 14.w),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: MyColors.border, width: 1),
      ),
      elevation: 2,
      shadowColor: MyColors.shadowMedium,
      color: MyColors.surface,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ━━ رأس البطاقة: موعد الانطلاق + الحالة ━━
              //
              // كان الرأس صورة السائق واسمه. وهذه «رحلاتي»: السائق هو
              // المستخدم نفسه دائماً، والخادم لا يرسل كائن `driver` في
              // `GET /rides` أصلاً — فكان يظهر إطار صورة فارغ وكلمة
              // «رحلتي». الموعد هو ما يميّز رحلة عن أخرى فعلاً.
              _DepartureHeader(departure: trip.departure, status: trip.status),

              SizedBox(height: 10.h),
              Divider(height: 1, color: MyColors.divider),
              SizedBox(height: 10.h),

              // ━━ المسار ━━
              //
              // كان سطرين وخيطاً بينهما — وافياً لشاشة التفاصيل، مسرفاً
              // في بطاقة قائمة حيث كل سطر يُقاس. صار طرفين وسهماً.
              TripRouteRow(
                from: trip.pickup.address,
                to: trip.destination.address,
              ),

              // المسافة والمدّة سطراً خافتاً تحت المسار لا رقاقة مستقلّة:
              // معلومة عن المسار نفسه، ومكانها تحته.
              if (trip.distance.meters > 0) ...[
                SizedBox(height: 8.h),
                _RouteMeta(
                  label: _routeLabel(
                      trip.distance.kilometers, trip.duration.minutes),
                ),
              ],

              SizedBox(height: 10.h),

              // ━━ الأرقام ━━
              //
              // كانت ستّ رقاقات في ثلاثة صفوف متساوية الوزن، فلا شيء
              // فيها يبرز. السعر أوّل ما يبحث عنه السائق والراكب، فيأخذ
              // حجمه، والمقاعد والحجوزات إلى جانبه بوزن أخفّ.
              _MetricsRow(
                price: Money.withCurrency(trip.pricePerSeat),
                seats: trip.seatsAvailable,
                bookings: trip.bookingsCount,
              ),

              // بلا شرط «هل الرحلة لي؟»: `GET /rides` لا يرجع إلا رحلات
              // المستخدم، وهذه البطاقة لا تُستعمل في غير «رحلاتي». وكان
              // الشرط يقارن `driver.id` بـ`myid()` فيبتلع كل الإجراءات
              // بصمت متى اختلّ أحد الطرفين — والصفّ الخام لا يرسل كائن
              // `driver` أصلاً، بل `driver_id` مفرداً.
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  /// إجراءات السائق على رحلته: **الإلغاء وحده**.
  ///
  /// زرّ «إنهاء الرحلة» أُزيل بتغيّر المتطلبات — السائق لم يعد يُنهي
  /// الرحلة، بل تكتمل بتأكيد الركّاب وصولهم.
  ///
  /// والإلغاء مقيَّد بـ [RideTimeRules.cancelCutoff]: نصف ساعة قبل
  /// الانطلاق. بعدها يبقى العدّ التنازلي معلومةً بلا زرّ، فيرى السائق
  /// أن الباب أُغلق بدل أن يضغط فيرفض الخادم.
  Widget _buildActions(BuildContext context) {
    final now = DateTime.now();
    final remaining = trip.departure.difference(now);

    // رحلة انطلقت: لا إجراء ولا عدّ
    if (RideTimeRules.hasDeparted(trip.departure, now: now)) {
      return const SizedBox.shrink();
    }

    // **الحالات المنتهية وحدها تمنع الإلغاء.** كان الشرط معكوساً — يسمح
    // لـ`active` وحدها — فأي حالة جديدة أو مكتوبة بحرف كبير من الخادم
    // تُخفي الزرّ بلا سبب ظاهر. والسماح عند الشكّ أسلم: الخادم يحسم.
    const closed = {'cancelled', 'canceled', 'finished', 'completed',
        'awaiting_confirmation', 'no_show'};
    if (closed.contains(trip.status.trim().toLowerCase())) {
      return const SizedBox.shrink();
    }

    // الرحلة لم تنطلق: الإلغاء متاح بلا مهلة مسبقة — انظر [RideTimeRules]
    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Row(
        children: [
          Expanded(child: _CountdownChip(remaining: remaining)),
          SizedBox(width: 10.w),
          _CancelButton(onCancel: onCancel),
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
      height: 38.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
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

/// إجراء هدّام: يُعرَض محدَّداً ومحدَّد اللون بالحدّ لا بالتعبئة، فلا يُضغط
/// سهواً ولا يسحب انتباه البطاقة إليه.
class _CancelButton extends StatelessWidget {
  final VoidCallback? onCancel;
  const _CancelButton({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
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

/// كتلة الموعد: رقم اليوم وشهره، ثم اسم اليوم والساعة، والحالة في الطرف.
class _DepartureHeader extends StatelessWidget {
  final DateTime departure;
  final String? status;

  const _DepartureHeader({required this.departure, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46.w,
          padding: EdgeInsets.symmetric(vertical: 6.h),
          decoration: BoxDecoration(
            color: MyColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
                color: MyColors.primary.withValues(alpha: 0.18), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${departure.day}',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: MyColors.primary,
                  height: 1.1,
                ),
              ),
              Text(
                DateTimeUtils.monthName(departure),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w600,
                  color: MyColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateTimeUtils.weekdayName(departure),
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Row(
                children: [
                  Icon(Icons.access_time_rounded,
                      size: 13.sp, color: MyColors.textSecondary),
                  SizedBox(width: 4.w),
                  Flexible(
                    child: Text(
                      DateTimeUtils.formatTime(departure),
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: MyColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 6.w),
        TripStatusBadge(status: status),
        SizedBox(width: 2.w),
        // إشارة أن للبطاقة عمقاً: الضغط يفتح الرحلة على الخريطة بحجوزاتها.
        // الأيقونة تنعكس مع اتجاه النصّ فتشير يساراً في الواجهة العربية.
        Icon(Icons.arrow_forward_ios_rounded,
            size: 13.sp, color: MyColors.textHint),
      ],
    );
  }
}

/// «47.8 كم · 41 د» تحت المسار.
class _RouteMeta extends StatelessWidget {
  final String label;
  const _RouteMeta({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(start: 30.w),
      child: Row(
        children: [
          Icon(Icons.route_rounded, size: 14.sp, color: MyColors.textSecondary),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall
                  .copyWith(color: MyColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// السعر بارزاً، والمقاعد والحجوزات إلى جانبه بوزن أخفّ.
///
/// **العنوان فئة والقيمة رقم** — لا «مقعدان» ولا «مقعد واحد متاح». صياغة
/// تطابق العدد تصير ركيكة فوق رقم: «2 مقعدان» تكرار، و«1 مقاعد» خطأ.
/// والصفر يظهر رقماً صريحاً بلون خافت، فلا يُقرأ «مقاعد متاحة» إثباتاً
/// على رحلة ممتلئة كما كان يحدث حين كان النصّ وحده.
class _MetricsRow extends StatelessWidget {
  final String price;
  final int seats;
  final int bookings;

  const _MetricsRow({
    required this.price,
    required this.seats,
    required this.bookings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: MyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: MyColors.textPrimary,
                  ),
                ),
                Text(
                  'للراكب الواحد',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: MyColors.textSecondary),
                ),
              ],
            ),
          ),
          const _CellDivider(),
          Expanded(
            flex: 2,
            child: _Metric(
              icon: Icons.event_seat_rounded,
              value: '$seats',
              label: 'مقاعد متاحة',
              color: seats > 0 ? MyColors.success : MyColors.textSecondary,
            ),
          ),
          const _CellDivider(),
          Expanded(
            flex: 2,
            child: _Metric(
              icon: Icons.people_alt_rounded,
              value: '$bookings',
              label: 'حجوزات مؤكَّدة',
              color: bookings > 0 ? MyColors.primary : MyColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 26.h,
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      color: MyColors.border,
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              AppTextStyles.labelSmall.copyWith(color: MyColors.textSecondary),
        ),
      ],
    );
  }
}
