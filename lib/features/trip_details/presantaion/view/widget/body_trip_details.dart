import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/class/ride_booking_rules.dart';
import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:alatarekak/core/utils/widgets/consequence_card.dart';
import 'package:alatarekak/core/utils/class/cancel_policy.dart';
import 'package:alatarekak/core/utils/functions/my_cancel_record.dart';
import 'package:alatarekak/core/utils/class/syrian_phone.dart';
import 'package:alatarekak/core/utils/widgets/syrian_phone_field.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/data/model/trip_details_mode.dart';
import 'package:alatarekak/features/trip_details/presantaion/manger/cubit/tripdetails_cubit.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';

/// تفاصيل الرحلة.
///
/// كانت الشاشة سلسلة عناصر متجاورة بلا تجميع: كل معلومة في حاوية بلون
/// وزاوية ومقاس مختلف، وبعضها بمقاسات ثابتة لا تتجاوب مع حجم الشاشة.
/// أُعيد تنظيمها إلى بطاقات موضوعية ([TripSectionCard]) بالمقاسات نفسها
/// المستعملة في بطاقات البحث و«رحلاتي»، فتُقرأ الشاشة كوحدة واحدة.
class BodyTripDetails extends StatefulWidget {
  final TripModel trip;
  final TripDetailsMode mode;
  const BodyTripDetails({super.key, required this.trip, required this.mode});

  @override
  State<BodyTripDetails> createState() => _BodyTripDetailsState();
}

class _BodyTripDetailsState extends State<BodyTripDetails> {
  TripModel get trip => widget.trip;

  /// حجز المستخدم الحالي على هذه الرحلة (إن وُجد).
  BookingModel? get _myBooking {
    for (final b in trip.booking) {
      if (b.userId == myid()) return b;
    }
    return null;
  }

  /// المحادثة مسموحة بين طرفين بينهما حجز فعلي فقط. الحجز المعلّق
  /// (pending) ليس حجزاً بعد — ينتظر موافقة السائق.
  bool get _canChatWithDriver {
    if (widget.mode != TripDetailsMode.otherView) return false;
    final status = _myBooking?.status;
    return status == 'confirmed' || status == 'completed';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeroCard(),
          _buildDriverCard(),
          _buildRouteCard(),
          _buildSeatsAndPriceCard(),
          _buildBookingTermsCard(),
          SizedBox(height: 4.h),
          _buildPrimaryAction(context),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━ الرأس ━━━━━━━━━━━━━━━━━━━

  /// بطاقة الموعد — أبرز ما يبحث عنه المستخدم عند فتح الرحلة، فتتصدّر
  /// الشاشة بلون الهوية بدل أن تكون سطراً بين أسطر.
  Widget _buildHeroCard() {
    final departure = trip.departure;
    final remaining = departure.difference(DateTime.now());

    final hour12 = departure.hour % 12 == 0 ? 12 : departure.hour % 12;
    final amPm = departure.hour >= 12 ? 'م' : 'ص';
    final time = '${hour12.toString().padLeft(2, '0')}:'
        '${departure.minute.toString().padLeft(2, '0')} $amPm';
    final date = '${departure.day.toString().padLeft(2, '0')}/'
        '${departure.month.toString().padLeft(2, '0')}/${departure.year}';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [MyColors.primary, MyColors.navy],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: MyColors.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded,
                  color: MyColors.accent, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'موعد الانطلاق',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TripStatusBadge(status: trip.status, solid: true),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              SizedBox(width: 10.w),
              // Flexible: الساعة بحجم 26 والتاريخ بجانبها في صفّ ثابت —
              // يكفي تاريخ أطول أو خطّ أعرض قليلاً ليفيض على شاشة ضيّقة.
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 3.h),
                  child: Text(
                    date,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timelapse_rounded,
                    color: MyColors.accent, size: 14.sp),
                SizedBox(width: 6.w),
                Text(
                  _remainingText(remaining),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _remainingText(Duration d) {
    if (d.inSeconds <= 0) return 'انطلقت الرحلة';
    if (d.inMinutes < 60) return 'بعد ${d.inMinutes} دقيقة';
    if (d.inHours < 24) {
      return 'بعد ${d.inHours} ساعة و${d.inMinutes % 60} دقيقة';
    }
    return 'بعد ${d.inDays} يوم و${d.inHours % 24} ساعة';
  }

  // ━━━━━━━━━━━━━━━━━━━ السائق ━━━━━━━━━━━━━━━━━━━

  /// بطاقة السائق — بلا رقم تواصل عمداً.
  ///
  /// رقم التواصل لا يُكشف لمن يتصفّح الرحلة، بل لمن قام بحجز فعلي فقط،
  /// ويظهر له في «حجوزاتي». وهي القاعدة نفسها التي تحكم المحادثة: لا
  /// وسيلة اتصال بين طرفين قبل قيام حجز بينهما.
  Widget _buildDriverCard() {
    final hasName = trip.driver.name.trim().isNotEmpty;

    return TripSectionCard(
      title: 'السائق',
      titleIcon: Icons.person_rounded,
      child: Column(
        children: [
          Row(
            children: [
              TripAvatar(
                avatar: trip.driver.avatar,
                size: 52,
                onTap: () => context
                    .read<TripDetailsCubit>()
                    .fetchProfile(trip.driver.id),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasName ? trip.driver.name : 'سائق الرحلة',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: trip.driver.rating,
                          itemBuilder: (context, index) =>
                              Icon(Icons.star_rounded, color: MyColors.warning),
                          itemCount: 5,
                          itemSize: 15.sp,
                          unratedColor: MyColors.border,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          trip.driver.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall
                              .copyWith(fontSize: 11.sp),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // مراسلة السائق — لا تُفتح محادثة إلا بين طرفين بينهما حجز
              // فعلي، فالزر يظهر لمن له حجز مؤكَّد أو مكتمل فقط
              if (_canChatWithDriver)
                _CircleAction(
                  icon: Icons.chat_bubble_rounded,
                  tooltip: 'مراسلة السائق',
                  onTap: () =>
                      context.read<TripDetailsCubit>().gotoChatWithDriver(
                            trip.driver.id,
                            name: trip.driver.name,
                            avatar: trip.driver.avatar,
                          ),
                ),
            ],
          ),
          // لا سطر رقم تواصل هنا — يُنظر إلى تعليق الدالة أعلاه.
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━ المسار ━━━━━━━━━━━━━━━━━━━

  Widget _buildRouteCard() {
    final distance = trip.distance;
    final duration = trip.duration;
    final distanceText = distance.kilometers >= 1
        ? '${distance.kilometers.toStringAsFixed(1)} كم'
        : '${distance.meters} م';
    final durationText = duration.minutes >= 60
        ? '${duration.minutes ~/ 60} س ${duration.minutes % 60} د'
        : '${duration.minutes} دقيقة';

    return TripSectionCard(
      title: 'المسار',
      titleIcon: Icons.route_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('عرض على الخريطة',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: MyColors.primary,
              )),
          Icon(Icons.chevron_left_rounded,
              size: 18.sp, color: MyColors.primary),
        ],
      ),
      onTap: () => Get.toNamed(
        RouteName.routeMapView,
        arguments: {
          'startLat': trip.pickup.coordinates.lat,
          'startLng': trip.pickup.coordinates.lng,
          'endLat': trip.destination.coordinates.lat,
          'endLng': trip.destination.coordinates.lng,
          'routeIndex': trip.chosenRouteIndex,
        },
      ),
      child: Column(
        // البدء من حافة السطر: الخيط الواصل يُرسم تحت الأيقونة تماماً،
        // ومع التوسيط الافتراضي كان ينزاح إلى منتصف البطاقة.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripLocationLine(
            label: 'نقطة الانطلاق',
            icon: Icons.circle,
            iconColor: MyColors.primary,
            text: trip.pickup.address,
          ),
          const TripRouteConnector(height: 22),
          TripLocationLine(
            label: 'الوجهة',
            icon: Icons.location_pin,
            iconColor: MyColors.accent,
            text: trip.destination.address,
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: Icons.straighten_rounded,
                  label: distanceText,
                  color: MyColors.blue,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: Icons.access_time_filled_rounded,
                  label: durationText,
                  color: MyColors.cyan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━ المقاعد والسعر ━━━━━━━━━━━━━━━━━━━

  Widget _buildSeatsAndPriceCard() {
    return TripSectionCard(
      title: 'المقاعد والسعر',
      titleIcon: Icons.event_seat_rounded,
      child: Row(
        children: [
          Expanded(
            // صفر قد يعني «ممتلئة» وقد يعني «لم يرسل الخادم العدّاد»،
            // ولا سبيل للتمييز — فلا يُعرض رقم يوحي بأحدهما. الشرطة أصدق.
            child: _StatTile(
              value: trip.seatsAvailable > 0 ? '${trip.seatsAvailable}' : '—',
              label: 'متاح',
              icon: Icons.event_available_rounded,
              color: MyColors.success,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: _StatTile(
              value: trip.seatsBooked > 0 ? '${trip.seatsBooked}' : '—',
              label: 'محجوز',
              icon: Icons.event_busy_rounded,
              color: MyColors.accent,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            flex: 2,
            child: _StatTile(
              value: Money.format(trip.pricePerSeat),
              label: 'ل.س للمقعد',
              icon: Icons.monetization_on_rounded,
              color: MyColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━ شروط الحجز ━━━━━━━━━━━━━━━━━━━

  Widget _buildBookingTermsCard() {
    final isCash = trip.paymentMethod.toLowerCase() == 'cash';
    final isDirect = trip.bookingType.toLowerCase() == 'direct';

    return TripSectionCard(
      title: 'شروط الحجز',
      titleIcon: Icons.rule_rounded,
      child: Column(
        children: [
          _TermRow(
            icon: isCash ? Icons.payments_rounded : Icons.credit_card_rounded,
            label: 'طريقة الدفع',
            value: isCash ? 'نقداً للسائق' : 'من المحفظة',
          ),
          SizedBox(height: 10.h),
          Divider(height: 1, color: MyColors.divider),
          SizedBox(height: 10.h),
          _TermRow(
            icon: isDirect
                ? Icons.bolt_rounded
                : Icons.hourglass_top_rounded,
            label: 'نوع الحجز',
            value: isDirect ? 'فوري بلا موافقة' : 'بموافقة السائق',
          ),
          if (trip.notes != null && trip.notes!.trim().isNotEmpty) ...[
            SizedBox(height: 10.h),
            Divider(height: 1, color: MyColors.divider),
            SizedBox(height: 10.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.sticky_note_2_rounded,
                    size: 16.sp, color: MyColors.textSecondary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ملاحظة السائق',
                          style: AppTextStyles.bodySmall
                              .copyWith(fontSize: 12.sp)),
                      SizedBox(height: 4.h),
                      Text(
                        trip.notes!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: MyColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━ الإجراء ━━━━━━━━━━━━━━━━━━━

  Widget _buildPrimaryAction(BuildContext context) {
    if (widget.mode == TripDetailsMode.myView) {
      // الإلغاء متاحٌ ما دامت لم تنطلق ولم تنتهِ — وكان غائباً عن هذه
      // الشاشة كلياً، فمن فتح رحلته ليراجعها قبل إلغائها وجب أن يعود
      // إلى القائمة ليجد الزرّ هناك.
      final canCancel = RideTimeRules.canCancelRide(trip.departure) &&
          !isRideOver(trip.status);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildBookingsListButton(),
          if (canCancel) ...[
            SizedBox(height: 10.h),
            _ActionButton(
              icon: Icons.cancel_schedule_send_rounded,
              label: 'إلغاء الرحلة',
              color: MyColors.error,
              onTap: () => _askCancelRide(context),
            ),
          ],
        ],
      );
    }
    return _buildConditionalBookingButton(context);
  }

  /// كلفة الإلغاء تُعرض قبله — انظر [CancelPolicy].
  Future<void> _askCancelRide(BuildContext context) async {
    final cubit = context.read<TripDetailsCubit>();
    final confirm = await showAppDialog(
      context,
      icon: Icons.cancel_schedule_send_rounded,
      title: 'إلغاء الرحلة',
      message: 'لا يمكن التراجع بعده.',
      content: ConsequenceCard(
        title: 'ماذا يقع إن ألغيتَ الآن',
        lines: CancelPolicy.driverCancelRide(
          elapsed: CancelPolicy.elapsedPercent(
            createdAt: trip.createdAt,
            departure: trip.departure,
          ),
          passengers: trip.activeBookingsCount,
          cashRide: trip.paymentMethod.trim().toLowerCase() == 'cash',
          repeatCanceller: amIRepeatCanceller(asDriver: true),
        ),
      ),
      confirmLabel: 'إلغاء الرحلة',
      cancelLabel: 'تراجع',
      destructive: true,
    );

    if (confirm == true) cubit.cancelTrip(trip.id);
  }

  Widget _buildBookingsListButton() {
    // **العدد من القائمة نفسها**: كان `seatsBooked` وهو يُقرأ من
    // `seats.booked` الصفريّة في هذا المسار، فيظهر «عرض الحجوزات (0)»
    // لسائقٍ يفتحه ليجد فيه ثلاثة حجوزات. وصفرٌ لا يُعرض أصلاً — الزرّ
    // بلا رقم أصدق من رقم كاذب.
    final count = trip.activeBookingsCount;

    return _ActionButton(
      icon: Icons.list_alt_rounded,
      label: count > 0 ? 'عرض الحجوزات ($count)' : 'عرض الحجوزات',
      color: MyColors.primary,
      // موعد الانطلاق وحالة الرحلة يُمرَّران معها: بلاغ «لم يحضر» لا
      // يظهر قبل الموعد بدقيقة ولا على رحلة انتهت، والحجز وحده لا يحمل
      // واحداً منهما
      onTap: () => Get.toNamed(
        RouteName.bookingUserInTrip,
        arguments: {
          'rideId': trip.id,
          'bookings': trip.booking,
          'departure': trip.departure,
          'rideStatus': trip.status,
          'paymentMethod': trip.paymentMethod,
        },
      ),
    );
  }

  Widget _buildConditionalBookingButton(BuildContext context) {
    final booking = _myBooking;

    switch (booking?.status) {
      case 'confirmed':
        return _statusAction(
            MyColors.success, 'تم قبول حجزك', Icons.check_circle_rounded);
      case 'pending':
        return _statusAction(
            MyColors.warning, 'طلبك بانتظار موافقة السائق',
            Icons.hourglass_top_rounded);
      case 'rejected':
        return _statusAction(
            MyColors.error, 'رُفض طلب الحجز', Icons.cancel_rounded);
      case 'cancelled':
        return _statusAction(
            MyColors.error, 'الحجز ملغى', Icons.cancel_rounded);
      case 'completed':
        return _statusAction(
            MyColors.success, 'حجز مكتمل', Icons.verified_rounded);
      case 'finished':
        return _statusAction(
            MyColors.textSecondary, 'انتهت الرحلة', Icons.flag_rounded);
      default:
        return _buildBookingButton(context);
    }
  }

  /// حالة الحجز ليست زرّاً — لا تُصاغ كزرّ يوحي بأن الضغط يفعل شيئاً.
  Widget _statusAction(Color color, String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingButton(BuildContext context) {
    return BlocBuilder<TripDetailsCubit, TripDetailsState>(
      builder: (context, state) {
        if (state is TripDetailsLoading) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            decoration: BoxDecoration(
              color: MyColors.primary.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Center(
              child: const AppLoader.onButton(),
            ),
          );
        }

        if (state is TripDetailsRequestBooking) {
          return _statusAction(
              MyColors.success, 'تم إرسال الحجز', Icons.check_circle_rounded);
        }

        // **الخادم لا يمنع حجز رحلة انطلقت ولا رحلة ألغيت** — أخطاء
        // `POST /rides/{id}/book` في المواصفة لا ذكر فيها للموعد ولا
        // للحالة. جُرّب فعلاً: رحلة مضى موعدها قَبِلت الحجز.
        final block = bookingBlockFor(
          status: trip.status,
          departure: trip.departure,
          seatsAvailable: trip.seatsAvailable,
        );

        if (block != null) {
          return _ActionButton(
            icon: _blockIcon(block),
            label: block.label,
            color: MyColors.textHint,
            onTap: () => _showBlockedDialog(context, block),
          );
        }

        return _ActionButton(
          icon: Icons.event_seat_rounded,
          label: 'احجز الآن — ${Money.withCurrency(trip.pricePerSeat)}',
          color: MyColors.primary,
          onTap: () => _showBookingDialog(context),
        );
      },
    );
  }

  // ━━━━━━━━━━━━━━━━━━━ الحوارات ━━━━━━━━━━━━━━━━━━━

  IconData _blockIcon(BookingBlock block) => switch (block) {
        BookingBlock.cancelled => Icons.cancel_rounded,
        BookingBlock.finished => Icons.flag_rounded,
        BookingBlock.departed => Icons.schedule_rounded,
        BookingBlock.full => Icons.event_busy_rounded,
      };

  /// **الزرّ يبقى ويشرح بدل أن يُخفى.** من فتح رحلة بحثاً عن الحجز يبحث
  /// عن هذا الزرّ، وغيابُه يجعله يظنّ التطبيق معطّلاً — والشرح يقول له
  /// ما يفعله بعده.
  void _showBlockedDialog(BuildContext context, BookingBlock block) {
    showAppDialog(
      context,
      icon: _blockIcon(block),
      accentColor: MyColors.error,
      title: block.title,
      message: block.message,
    );
  }

  void _showBookingDialog(BuildContext context) {
    // حين يصل العدّاد صفراً لا نعرف أهي ممتلئة أم أن الحقل لم يُقرأ، فلا
    // يُقيَّد المستخدم بصفر. الحدّ حينها هو سقف الخادم لكل حجز (8 مقاعد)،
    // وهو من يرفض إن لم تكفِ المقاعد.
    const int serverSeatCap = 8;
    final int maxSeats =
        trip.seatsAvailable > 0 ? trip.seatsAvailable : serverSeatCap;

    showDialog(
      context: context,
      builder: (dialogContext) => _BookingDialog(
        maxSeats: maxSeats,
        seatsKnown: trip.seatsAvailable > 0,
        pricePerSeat: trip.pricePerSeat,
        onConfirm: (seats, phone) => _bookSeats(seats, trip.id, phone),
      ),
    );
  }

  void _bookSeats(int seats, int tripId, String contactNumber) async {
    await context
        .read<TripDetailsCubit>()
        .booking(seats, tripId, contactNumber);
  }
}

// ━━━━━━━━━━━━━━━━━━━ لبنات محلّية ━━━━━━━━━━━━━━━━━━━

/// إحصاءة مفردة داخل بطاقة — رقم بارز فوق تسميته.
class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
                fontSize: 10.sp, color: MyColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TermRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TermRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: MyColors.textSecondary),
        SizedBox(width: 8.w),
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: MyColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: MyColors.primary.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(10.w),
            child: Icon(icon, color: MyColors.primary, size: 18.sp),
          ),
        ),
      ),
    );
  }
}

/// زرّ الإجراء الرئيسي — شكل واحد لكل أزرار الشاشة، وحالته المعطّلة
/// مقروءة بلا نصّ إضافي.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SizedBox(
      height: 52.h,
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MyColors.surfaceAlt,
          disabledForegroundColor: MyColors.textHint,
          elevation: enabled ? 2 : 0,
          shadowColor: color.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        ),
        icon: Icon(icon, size: 20.sp),
        label: Text(
          label,
          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// حوار الحجز — عدّاد مقاعد محدود بالمتاح، وحقل هاتف يقبل الصيغتين.
///
/// كان العدد يُكتب نصّاً فيُترك للمستخدم أن يخطئ ثم يُصحَّح برسالة تحقّق.
/// العدّاد يمنع الخطأ ابتداءً: لا يتجاوز المتاح ولا ينزل تحت مقعد واحد.
class _BookingDialog extends StatefulWidget {
  final int maxSeats;
  final bool seatsKnown;
  final String pricePerSeat;
  final void Function(int seats, String phone) onConfirm;

  const _BookingDialog({
    required this.maxSeats,
    required this.seatsKnown,
    required this.pricePerSeat,
    required this.onConfirm,
  });

  @override
  State<_BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<_BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  int _seats = 1;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  double? get _unitPrice => double.tryParse(widget.pricePerSeat);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MyColors.surface,
      insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      contentPadding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 8.h),
      title: Row(
        children: [
          Icon(Icons.event_seat_rounded, color: MyColors.accent, size: 22.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text('حجز مقاعد',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 16.sp)),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _availabilityNote(),
              SizedBox(height: 16.h),
              _seatsStepper(),
              SizedBox(height: 16.h),
              _phoneField(),
            ],
          ),
        ),
      ),
      actionsPadding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('إلغاء',
              style:
                  TextStyle(color: MyColors.textSecondary, fontSize: 14.sp)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: MyColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r)),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          ),
          onPressed: _submit,
          child: Text('تأكيد الحجز',
              style:
                  TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // يُرسَل الرقم مطبَّعاً لا كما كُتب: الخادم يقبل 09XXXXXXXX وحدها
    final phone = SyrianPhone.normalize(_phone.text) ?? _phone.text.trim();
    Navigator.pop(context);
    widget.onConfirm(_seats, phone);
  }

  Widget _availabilityNote() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.accentLight,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16.sp, color: MyColors.accent),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              widget.seatsKnown
                  ? 'المتاح ${widget.maxSeats} مقاعد — سعر المقعد '
                      '${Money.withCurrency(widget.pricePerSeat)}'
                  : 'سعر المقعد ${Money.withCurrency(widget.pricePerSeat)} — '
                      'يؤكّد الخادم توفّر المقاعد عند الإرسال',
              style: TextStyle(fontSize: 12.sp, color: MyColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seatsStepper() {
    final unit = _unitPrice;
    final atMin = _seats <= 1;
    final atMax = _seats >= widget.maxSeats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('عدد المقاعد',
            style: AppTextStyles.labelMedium.copyWith(fontSize: 13.sp)),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: MyColors.background,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: MyColors.border, width: 1),
          ),
          child: Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                enabled: !atMin,
                onTap: () => setState(() => _seats--),
              ),
              Expanded(
                child: Text(
                  '$_seats',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: MyColors.textPrimary,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                enabled: !atMax,
                onTap: () => setState(() => _seats++),
              ),
            ],
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            if (atMax && widget.seatsKnown)
              Expanded(
                child: Text(
                  'بلغتَ أقصى المتاح',
                  style: TextStyle(fontSize: 11.sp, color: MyColors.textHint),
                ),
              )
            else
              const Spacer(),
            if (unit != null)
              Text(
                'الإجمالي ${Money.withCurrency(unit * _seats)}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: MyColors.accent,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _phoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('رقم التواصل',
            style: AppTextStyles.labelMedium.copyWith(fontSize: 13.sp)),
        SizedBox(height: 8.h),
        SyrianPhoneField(
          controller: _phone,
          fillColor: MyColors.background,
          helperText: 'يُقبل 0988626577 أو +963988626577',
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = enabled ? MyColors.primary : MyColors.textHint;
    return Material(
      color: enabled
          ? MyColors.primary.withValues(alpha: 0.1)
          : MyColors.surfaceAlt.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(10.r),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Icon(icon, size: 20.sp, color: color),
        ),
      ),
    );
  }
}
