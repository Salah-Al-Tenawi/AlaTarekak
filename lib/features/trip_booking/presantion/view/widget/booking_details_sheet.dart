import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/no_show_report_store.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/class/cancel_policy.dart';
import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/core/utils/widgets/consequence_card.dart';
import 'package:alatarekak/core/utils/widgets/no_show_gate.dart';
import 'package:alatarekak/core/utils/widgets/rate_user_sheet.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_time_text.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/cancel_seats_sheet.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/status_trip.dart';

/// ورقة تفاصيل الحجز الكاملة — ما كانت بطاقة «حجوزاتي» تعرضه كلّه دفعة
/// واحدة داخل القائمة.
///
/// كانت البطاقة الواحدة تملأ الشاشة: المسار والموعد والعدّاد والأرقام
/// ورقما التواصل ونوع المركبة وطريقة الدفع وزرّ الإجراء — فصار تصفّح
/// خمسة حجوزات تمريراً طويلاً بلا نظرة عامة. البطاقة الآن ملخّص، وهذه
/// الورقة هي التفصيل عند الطلب.
///
/// **الإجراءات تُغلق الورقة فور إرسالها**، والقائمة هي التي تعرض النتيجة
/// وتُحدّث نفسها: إبقاء الورقة مفتوحة حتى يصل الردّ يجعل إغلاقها معتمداً
/// على ترتيب مستمعَين على الكيوبت نفسه — فقد يُغلق الحوار الذي تعرضه
/// القائمة بدل الورقة.
class BookingDetailsSheet extends StatelessWidget {
  final BookingMe booking;

  const BookingDetailsSheet({super.key, required this.booking});

  /// يفتح الورقة فوق الشاشة الحالية. الكيوبت يُمرَّر صراحةً لأن الورقة
  /// تُدفع على ملّاح الجذر، خارج شجرة الشاشة التي تملك المزوّد.
  static Future<void> show(BuildContext context, BookingMe booking) {
    final cubit = context.read<BookingMeCubit>();

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: MyColors.navy.withValues(alpha: 0.45),
      builder: (_) => BlocProvider<BookingMeCubit>.value(
        value: cubit,
        child: BookingDetailsSheet(booking: booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, controller) => BookingDetailsContent(
        booking: booking,
        scrollController: controller,
      ),
    );
  }
}

/// جسم الورقة — مفصول عن غلاف السحب ليُختبر وحده بلا ورقة مشروطة.
class BookingDetailsContent extends StatefulWidget {
  final BookingMe booking;
  final ScrollController? scrollController;

  const BookingDetailsContent({
    super.key,
    required this.booking,
    this.scrollController,
  });

  @override
  State<BookingDetailsContent> createState() => _BookingDetailsContentState();
}

class _BookingDetailsContentState extends State<BookingDetailsContent> {
  BookingMe get b => widget.booking;

  late final StatusInfo _rideStatus = getStatusInfo(b.rideStatus);

  /// سياسة التطبيق: لا محادثة بلا حجز — والحجز هنا يجب أن يكون **قائماً**
  /// لا مجرّد طلب أو حجزٍ انتهى بالرفض أو الإلغاء.
  ///
  /// `pending` مستثنى ليطابق جانب السائق: زرّ المراسلة في شاشة حجوزات
  /// الرحلة لا يظهر إلا بعد قبول الحجز، فلا يصحّ أن يراسل الراكب طرفاً
  /// لا يستطيع الردّ عليه من شاشته.
  bool get _chatAllowed => const {
        'confirmed',
        'accepted',
        'ongoing',
        'completed',
        'finished',
      }.contains(b.status.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _grabHandle(),
          _sheetHeader(),
          Divider(height: 1, color: MyColors.divider),
          Flexible(
            child: ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 4.h),
              children: [
                _driverCard(),
                _routeCard(),
                _timingCard(),
                _moneyCard(),
                _contactsCard(),
                _rideLinkCard(),
              ],
            ),
          ),
          _actionBar(),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ الرأس ━━━━━━━━━━━━━━━━

  Widget _grabHandle() => Padding(
        padding: EdgeInsets.only(top: 10.h, bottom: 6.h),
        child: Container(
          width: 44.w,
          height: 4.h,
          decoration: BoxDecoration(
            color: MyColors.border,
            borderRadius: BorderRadius.circular(4.r),
          ),
        ),
      );

  Widget _sheetHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 8.w, 10.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'تفاصيل الحجز',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 16.sp),
            ),
          ),
          TripStatusBadge(status: b.status),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close_rounded, size: 20.sp),
            tooltip: 'إغلاق',
            visualDensity: VisualDensity.compact,
            color: MyColors.textSecondary,
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ السائق ━━━━━━━━━━━━━━━━

  Widget _driverCard() {
    return TripSectionCard(
      child: Row(
        children: [
          TripAvatar(
            avatar: b.driverAvatar,
            size: 52,
            onTap: () =>
                Get.toNamed(RouteName.profile, arguments: b.userDriver),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.driverName.trim().isEmpty ? 'سائق الرحلة' : b.driverName,
                  style: AppTextStyles.bodyLarge
                      .copyWith(fontSize: 15.sp, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                if (b.driverRating > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.star_rounded,
                          size: 15.sp, color: MyColors.warning),
                      SizedBox(width: 3.w),
                      Text(
                        b.driverRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: MyColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                ],
                Text(
                  'حجز رقم ${b.bookingId} · '
                  'حُجز في ${DateTimeUtils.formatDate(b.bookingDate)}',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 11.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_chatAllowed) _ChatButton(booking: b),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ المسار ━━━━━━━━━━━━━━━━

  Widget _routeCard() {
    final hasDistance = b.distanceKm > 0;
    final hasDuration = b.durationMinutes > 0;

    return TripSectionCard(
      title: 'المسار',
      titleIcon: Icons.route_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripLocationLine(
            label: 'نقطة الانطلاق',
            icon: Icons.circle,
            iconColor: MyColors.primary,
            text: b.pickupAddress,
          ),
          const TripRouteConnector(),
          TripLocationLine(
            label: 'الوجهة',
            icon: Icons.location_pin,
            iconColor: MyColors.accent,
            text: b.destinationAddress,
          ),
          if (hasDistance || hasDuration) ...[
            SizedBox(height: 12.h),
            Row(
              children: [
                if (hasDistance)
                  Expanded(
                    child: TripInfoChip(
                      expand: true,
                      icon: Icons.straighten_rounded,
                      label: '${b.distanceKm.toStringAsFixed(0)} كم',
                      color: MyColors.textSecondary,
                    ),
                  ),
                if (hasDistance && hasDuration) SizedBox(width: 8.w),
                if (hasDuration)
                  Expanded(
                    child: TripInfoChip(
                      expand: true,
                      icon: Icons.timer_outlined,
                      label: '${b.durationMinutes} دقيقة',
                      color: MyColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ الموعد ━━━━━━━━━━━━━━━━

  Widget _timingCard() {
    final departed = RideTimeRules.hasDeparted(b.departureTime);

    return TripSectionCard(
      title: 'الموعد',
      titleIcon: Icons.event_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: Icons.calendar_today_rounded,
                  label: DateTimeUtils.arabicDate(b.departureTime),
                  color: MyColors.primary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: Icons.access_time_rounded,
                  label: DateTimeUtils.formatTime(b.departureTime),
                  color: MyColors.accent,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
            decoration: BoxDecoration(
              color: departed ? MyColors.surfaceAlt : MyColors.warningLight,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: departed
                    ? MyColors.border
                    : MyColors.warning.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  departed ? Icons.flag_rounded : Icons.schedule_rounded,
                  size: 15.sp,
                  color: departed ? MyColors.textSecondary : MyColors.warning,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    countdownToDeparture(b.departureTime),
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
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ المال والمركبة ━━━━━━━━━━━━━━━━

  Widget _moneyCard() {
    final isCash = b.paymentMethod.toLowerCase() == 'cash';

    return TripSectionCard(
      title: 'التفاصيل المالية',
      titleIcon: Icons.receipt_long_rounded,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(
                  icon: Icons.event_seat_rounded,
                  value: '${b.seats}',
                  label: 'مقعد',
                  color: MyColors.success,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: _Stat(
                  icon: Icons.sell_rounded,
                  value: Money.format(b.pricePerSeat),
                  label: 'ل.س للمقعد',
                  color: MyColors.textSecondary,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                flex: 2,
                child: _Stat(
                  icon: Icons.payments_rounded,
                  value: Money.format(b.totalPrice),
                  label: 'الإجمالي',
                  color: MyColors.warning,
                  emphasized: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: isCash
                      ? Icons.payments_rounded
                      : Icons.account_balance_wallet_rounded,
                  label: isCash ? 'نقداً للسائق' : 'من المحفظة',
                  color: MyColors.blue,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: Icons.directions_car_rounded,
                  label: b.vehicleType.trim().isEmpty ? 'مركبة' : b.vehicleType,
                  color: MyColors.textSecondary,
                ),
              ),
              // حالة الرحلة لا يرسلها هذا المسار دائماً — تُخفى بدل عرض
              // مربّع «غير معروف»
              if (_rideStatus.isKnown) ...[
                SizedBox(width: 8.w),
                Expanded(
                  child: TripInfoChip(
                    expand: true,
                    icon: Icons.trip_origin_rounded,
                    label: _rideStatus.text,
                    color: _rideStatus.color,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ أرقام التواصل ━━━━━━━━━━━━━━━━

  /// رقما التواصل: رقم السائق (للاتصال به) ورقم الراكب المسجَّل في هذا
  /// الحجز (ليعرف على أي رقم سيصله الاتصال). كلاهما يصل من الخادم.
  Widget _contactsCard() {
    final driverPhone = b.driverCommunicationNumber.trim();
    final myPhone = b.passengerCommunicationNumber.trim();
    if (driverPhone.isEmpty && myPhone.isEmpty) return const SizedBox.shrink();

    return TripSectionCard(
      title: 'أرقام التواصل',
      titleIcon: Icons.phone_rounded,
      child: Column(
        children: [
          if (driverPhone.isNotEmpty)
            _PhoneRow(
              icon: Icons.support_agent_rounded,
              label: 'رقم السائق',
              phone: driverPhone,
              onCall: () => _dial(driverPhone),
            ),
          if (driverPhone.isNotEmpty && myPhone.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Divider(height: 1, color: MyColors.divider),
            SizedBox(height: 8.h),
          ],
          if (myPhone.isNotEmpty)
            _PhoneRow(
              icon: Icons.person_rounded,
              label: 'رقمي في هذا الحجز',
              phone: myPhone,
            ),
        ],
      ),
    );
  }

  Future<void> _dial(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      showMySnackBar(context, 'تعذّر فتح تطبيق الاتصال',
          type: SnackType.error);
    }
  }

  // ━━━━━━━━━━━━━━━━ الانتقال إلى الرحلة ━━━━━━━━━━━━━━━━

  /// كان الضغط على البطاقة يفتح تفاصيل الرحلة مباشرة. صار للبطاقة معنى
  /// آخر (فتح هذه الورقة)، فالطريق إلى الرحلة يبقى صريحاً هنا.
  Widget _rideLinkCard() {
    return TripSectionCard(
      onTap: () {
        Navigator.of(context).maybePop();
        Get.toNamed(RouteName.tripDetails, arguments: b.rideId);
      },
      child: Row(
        children: [
          Icon(Icons.map_rounded, size: 18.sp, color: MyColors.primary),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'عرض تفاصيل الرحلة كاملة',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: MyColors.primary,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14.sp, color: MyColors.textHint),
        ],
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ الإجراءات ━━━━━━━━━━━━━━━━

  Widget _actionBar() {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.surface,
        border: Border(top: BorderSide(color: MyColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          child: _buildActionButtons(b.status),
        ),
      ),
    );
  }

  /// يُرسل الإجراء ثم يُغلق الورقة فوراً — القائمة تعرض النتيجة وتُحدّث
  /// نفسها، فلا يبقى المستخدم أمام ورقة عن حجز تغيّرت حاله.
  void _dispatch(void Function(BookingMeCubit cubit) action) {
    final cubit = context.read<BookingMeCubit>();
    Navigator.of(context).maybePop();
    action(cubit);
  }

  Widget _buildActionButtons(String bookingState) {
    final departed = RideTimeRules.hasDeparted(b.departureTime);

    switch (bookingState.trim().toLowerCase()) {
      case 'completed':
        return _Action(
          icon: Icons.star_rate_rounded,
          label: 'انتهت الرحلة — قيّم السائق',
          color: MyColors.accent,
          onTap: () => _showRatingDialog(b.userDriver),
        );

      case 'cancelled':
      case 'canceled':
        return _Action(
          icon: Icons.block_rounded,
          label: 'الحجز ملغى',
          color: MyColors.error,
          onTap: null,
        );

      case 'rejected':
        return _Action(
          icon: Icons.cancel_rounded,
          label: 'رُفض طلب الحجز',
          color: MyColors.error,
          onTap: null,
        );

      case 'finished':
        return _Action(
          icon: Icons.check_circle_rounded,
          label: 'انتهت الرحلة',
          color: MyColors.success,
          onTap: null,
        );

      case 'pending':
        return _Action(
          icon: Icons.close_rounded,
          label: 'إلغاء الطلب',
          color: MyColors.error,
          outlined: true,
          onTap: _askCancelSeats,
        );

      default:
        // ثلاث مراحل: قبل الانطلاق إلغاء الحجز، ومع الانطلاق تأكيد
        // الوصول، وبعد دقيقة منه يُضاف بلاغ غياب السائق. **والإلغاء
        // يبقى متاحاً في كلّها** — انظر [_lateCancelAction].
        if (!departed) {
          return _Action(
            icon: Icons.close_rounded,
            label: 'إلغاء الحجز',
            color: MyColors.error,
            outlined: true,
            onTap: _askCancelSeats,
          );
        }
        final confirmAction = _Action(
          icon: Icons.check_rounded,
          label: 'تأكيد الوصول',
          color: MyColors.primary,
          onTap: () async {
            final confirm = await showAppDialog(
              context,
              icon: Icons.check_circle_outline_rounded,
              title: 'تأكيد الوصول؟',
              message: 'تأكيدك يعني وصولك إلى وجهتك ونجاح الرحلة، وبه '
                  'تكتمل الرحلة ويُحرَّر المبلغ للسائق.',
              confirmLabel: 'تأكيد الوصول',
              cancelLabel: 'تراجع',
            );
            if (!(confirm ?? false) || !mounted) return;
            _dispatch((cubit) => cubit.finishTrip(b.bookingId));
          },
        );

        // البوابة تحكم الصفّ كلّه لا الزرّ وحده: ما دامت مغلقة فتأكيد
        // الوصول يأخذ العرض كاملاً، فلا يبقى خُمساه فراغاً مكان زرّ
        // مخفيّ. وهي تفتح نفسها بعد دقيقة والراكب أمام الورقة.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NoShowGate(
              departure: b.departureTime,
              builder: (context, remaining) {
                if (remaining != null) return confirmAction;

                return Row(
                  children: [
                    Expanded(flex: 3, child: confirmAction),
                    SizedBox(width: 8.w),
                    Expanded(flex: 2, child: _noShowAction()),
                  ],
                );
              },
            ),
            SizedBox(height: 8.h),
            _lateCancelAction(),
          ],
        );
    }
  }

  /// إلغاء الحجز بعد الانطلاق — **يُحذَّر منه ولا يُمنع**.
  ///
  /// كان الزرّ يختفي مع الانطلاق، فيبقى الراكب الذي لم يركب أصلاً بحجزٍ
  /// لا سبيل له إلى إنهائه. والخادم لا يرفض الإلغاء المتأخّر — فالمنع
  /// كان حجباً لفعلٍ مسموح، لا حمايةً من رفضٍ آتٍ.
  ///
  /// وكلفته تُقال قبله لا بعده: بعد انقضاء 70% من المدّة لا يُسترد شيء
  /// وتُخصم عشر نقاط ثقة — انظر سياسة الإلغاء.
  Widget _lateCancelAction() => _Action(
        icon: Icons.close_rounded,
        label: 'إلغاء الحجز',
        color: MyColors.textSecondary,
        outlined: true,
        onTap: () async {
          final go = await showAppDialog(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'إلغاء بعد الانطلاق؟',
            message: 'انطلقت الرحلة، فالإلغاء الآن لا يُرتّب استرداداً '
                'وتُخصم 10 نقاط من ثقتك. إن كنت قد وصلت فأكّد وصولك، '
                'وإن لم يحضر السائق فأبلغ عن غيابه — كلاهما أنفع لك.',
            confirmLabel: 'إلغاء الحجز',
            cancelLabel: 'تراجع',
            destructive: true,
          );
          if (!(go ?? false) || !mounted) return;
          await _askCancelSeats();
        },
      );

  /// زرّ «لم يحضر» بعد أن تُفتح بوابته.
  ///
  /// **يُخفى قبل أوانه ولا يُعطَّل**: بلاغ الغياب على حجز مؤكَّد لم
  /// تنطلق رحلته بعد إنذارٌ في غير موضعه، والمهلة صارت دقيقة واحدة فلا
  /// عدّاد يستحق العرض. والمُبلَّغ عنه سابقاً يُعطَّل — الحالة محفوظة
  /// محلياً لأن الخادم لا يكشف تقارير الغياب في أي مسار.
  Widget _noShowAction() {
    if (NoShowReportStore.wasReported(NoShowReportStore.rideKey(b.rideId))) {
      return _Action(
        icon: Icons.flag_rounded,
        label: 'تم الإبلاغ',
        color: MyColors.textSecondary,
        outlined: true,
        onTap: null,
      );
    }

    return _reportAction();
  }

  Widget _reportAction() {
    return _Action(
      icon: Icons.report_problem_rounded,
      label: 'لم يحضر',
      color: MyColors.error,
      outlined: true,
      onTap: () async {
        final driver = b.driverName.trim().isEmpty ? 'السائق' : b.driverName;
        // مطابق لحوار السائق عن راكبه: الإجراء واحد، فلا يصحّ أن يختلف
        // شكله ولا نبرته باختلاف من يقوم به.
        final confirm = await showAppDialog(
          context,
          icon: Icons.report_problem_outlined,
          title: 'السائق لم يحضر؟',
          message: 'بلاغٌ بحقّ $driver — لا تُرسله إلا بعد انتظاره فعلاً.',
          content: ConsequenceCard(
            title: 'ماذا يحدث بعد البلاغ',
            lines: CancelPolicy.noShowReport(
              againstPassenger: false,
              cashRide: b.paymentMethod.trim().toLowerCase() == 'cash',
            ),
          ),
          confirmLabel: 'تسجيل البلاغ',
          cancelLabel: 'تراجع',
          destructive: true,
        );
        if (!(confirm ?? false) || !mounted) return;
        _dispatch((cubit) => cubit.reportDriverNoShow(b.rideId));
      },
    );
  }

  /// **خطوة واحدة**: كان حواراً يختار العدد ثم حواراً يسأل «هل أنت
  /// متأكد؟» بنصّ يكرّر ما قيل للتوّ. الورقة تعرض أثر الاختيار — كم
  /// مقعداً يبقى، ومتى يصير الإلغاء كاملاً — فيُغني عن السؤال الثاني.
  Future<void> _askCancelSeats() async {
    final cashRide = b.paymentMethod.trim().toLowerCase() == 'cash';
    final seatsToCancel = await CancelSeatsSheet.show(
      context,
      bookedSeats: b.seats,
      pricePerSeat: b.pricePerSeat,
      // النسبة من عمر الحجز لا من قربه للانطلاق — انظر [CancelPolicy]
      elapsedPercent: CancelPolicy.elapsedPercent(
        createdAt: b.bookingDate,
        departure: b.departureTime,
      ),
      cashRide: cashRide,
    );
    if (seatsToCancel == null || !mounted) return;

    // **مسار واحد للحالتين**: `cancel-seats` يقبل إلغاء كل المقاعد
    // ويردّ تفاصيل الاسترداد، بينما `/cancel` يُنهي الحجز بلا رقم —
    // فكان من يلغي حجزه كاملاً لا يعرف كم أُعيد إليه.
    final status = b.status.trim().toLowerCase();
    _dispatch((cubit) => cubit.cancelBooking(
          b.bookingId,
          seatsToCancel,
          wasConfirmed: status != 'pending',
          cashRide: cashRide,
        ));
  }

  /// تقييم السائق — ورقة واحدة مشتركة مع جانب السائق.
  ///
  /// كان حواراً مبنيّاً يدوياً بمقاسات ثابتة لا تتبع الشاشة، ونجومه بلا
  /// تسمية تقول ماذا تعني الثلاث من الخمس، وبلا موضع لتعليق — ومسار
  /// التعليق موجود في الخادم ولا يناديه أحد.
  Future<void> _showRatingDialog(int userId) async {
    final cubit = context.read<BookingMeCubit>();
    final driver =
        b.driverName.trim().isEmpty ? 'سائق الرحلة' : b.driverName;

    final result = await RateUserSheet.show(
      context,
      name: driver,
      question: 'كيف كانت رحلتك مع $driver؟',
      avatar: b.driverAvatar,
    );
    if (result == null || !mounted) return;

    // الورقة تُغلق ثم يُرسَل، كبقيّة إجراءاتها
    Navigator.of(context).maybePop();
    cubit.reateUser(result.rating, userId, b.rideId,
        comment: result.comment);
  }
}

// ━━━━━━━━━━━━━━━━━━━ لبنات محلّية ━━━━━━━━━━━━━━━━━━━

/// خانة رقمية داخل الورقة — رقم فوق تسميته، بعرض متساوٍ مع أخواتها.
class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool emphasized;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: emphasized ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
            color: color.withValues(alpha: emphasized ? 0.3 : 0.15), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 15.sp, color: color),
          SizedBox(height: 5.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: emphasized ? 15.sp : 14.sp,
                fontWeight: FontWeight.bold,
                color: emphasized ? color : MyColors.textPrimary,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(fontSize: 10.sp, color: MyColors.textHint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// سطر رقم تواصل — يُتاح الاتصال منه حين يكون الرقم لطرف آخر.
class _PhoneRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String phone;
  final VoidCallback? onCall;

  const _PhoneRow({
    required this.icon,
    required this.label,
    required this.phone,
    this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: MyColors.textSecondary),
        SizedBox(width: 8.w),
        Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp)),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            phone,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: MyColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onCall != null) ...[
          SizedBox(width: 6.w),
          Material(
            color: MyColors.success.withValues(alpha: 0.12),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onCall,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(7.w),
                child: Icon(Icons.call_rounded,
                    size: 16.sp, color: MyColors.success),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// زرّ إجراء بشكل واحد لكل حالات الورقة — والمعطّل يُقرأ معطّلاً.
class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool outlined;

  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r));
    final text = Text(
      label,
      style: TextStyle(fontSize: 13.5.sp, fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return SizedBox(
      height: 48.h,
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side:
                    BorderSide(color: color.withValues(alpha: 0.5), width: 1.2),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                shape: shape,
              ),
              icon: Icon(icon, size: 17.sp),
              label: text,
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: color.withValues(alpha: 0.12),
                disabledForegroundColor: color,
                elevation: onTap == null ? 0 : 2,
                shadowColor: color.withValues(alpha: 0.35),
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                shape: shape,
              ),
              icon: Icon(icon, size: 17.sp),
              label: text,
            ),
    );
  }
}

// ━━━━━━━━━━━━━━━━ مراسلة السائق ━━━━━━━━━━━━━━━━

/// أيقونة فتح المحادثة مع سائق الحجز.
///
/// الخادم يعيد المحادثة القائمة إن وُجدت بدل إنشاء ثانية، فالأيقونة
/// واحدة: تفتح الموجودة أو تُنشئها. ولا حاجة لجلب الرحلة لمعرفة السائق —
/// [BookingMe] يحمل معرّفه واسمه وصورته.
class _ChatButton extends StatelessWidget {
  final BookingMe booking;
  const _ChatButton({required this.booking});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'مراسلة السائق',
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints(minWidth: 38.w, minHeight: 38.w),
      padding: EdgeInsets.zero,
      onPressed: () {
        final cubit = context.read<BookingMeCubit>();
        // الورقة تُغلق أولاً: القائمة هي التي تنتقل إلى المحادثة، ولو
        // بقيت مفتوحة لعادت فوق شاشة المحادثة.
        Navigator.of(context).maybePop();
        cubit.openChatWithDriver(
          userId: booking.userDriver,
          name: booking.driverName.trim().isEmpty
              ? 'سائق الرحلة'
              : booking.driverName,
          avatar: booking.driverAvatar,
        );
      },
      icon: Container(
        width: 34.w,
        height: 34.w,
        decoration: BoxDecoration(
          color: MyColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(Icons.chat_bubble_outline_rounded,
            size: 18.sp, color: MyColors.primary),
      ),
    );
  }
}
