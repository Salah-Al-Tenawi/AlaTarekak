import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/my_button.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/widget/status_trip.dart';

/// بطاقة حجز في «حجوزاتي».
///
/// أُعيد بناؤها على لبنات بطاقة الرحلة المشتركة ([TripAvatar]،
/// [TripLocationLine]، [TripInfoChip]) فصارت تُقرأ كبقية قوائم التطبيق،
/// وبمقاسات متجاوبة بدل الثوابت التي كانت تتمدّد على الشاشات الصغيرة.
class BookingItem extends StatefulWidget {
  final BookingMe booking;
  final VoidCallback onTapDetails;

  const BookingItem({
    super.key,
    required this.booking,
    required this.onTapDetails,
  });

  @override
  State<BookingItem> createState() => _BookingItemState();
}

class _BookingItemState extends State<BookingItem> {
  late final StatusInfo statusInfoRide;
  late final StatusInfo statusInfobooking;

  BookingMe get b => widget.booking;

  @override
  void initState() {
    statusInfoRide = getStatusInfo(widget.booking.rideStatus);
    statusInfobooking = getStatusInfo(widget.booking.status);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);

    return Card(
      elevation: 3,
      shadowColor: MyColors.shadowMedium,
      color: MyColors.surface,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: MyColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: widget.onTapDetails,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 14.h),
              Divider(height: 1, color: MyColors.divider),
              SizedBox(height: 14.h),
              _buildRoute(),
              SizedBox(height: 14.h),
              _buildWhen(),
              SizedBox(height: 8.h),
              _buildNumbers(),
              SizedBox(height: 12.h),
              _buildContacts(),
              SizedBox(height: 12.h),
              _buildMeta(),
              SizedBox(height: 14.h),
              _buildActionArea(),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ الرأس ━━━━━━━━━━━━━━━━

  Widget _buildHeader() {
    return Row(
      children: [
        TripAvatar(
          avatar: b.driverAvatar,
          size: 46,
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
              SizedBox(height: 3.h),
              Text('حجز رقم ${b.bookingId}',
                  style: AppTextStyles.labelSmall.copyWith(fontSize: 11.sp)),
            ],
          ),
        ),
        SizedBox(width: 4.w),
        if (_chatAllowed) _ChatButton(booking: b),
        SizedBox(width: 4.w),
        TripStatusBadge(status: b.status),
      ],
    );
  }

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

  // ━━━━━━━━━━━━━━━━ المسار ━━━━━━━━━━━━━━━━

  Widget _buildRoute() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripLocationLine(
          icon: Icons.circle,
          iconColor: MyColors.primary,
          text: b.pickupAddress,
        ),
        const TripRouteConnector(),
        TripLocationLine(
          icon: Icons.location_pin,
          iconColor: MyColors.accent,
          text: b.destinationAddress,
        ),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━ الموعد ━━━━━━━━━━━━━━━━

  Widget _buildWhen() {
    final departed = b.departureTime.isBefore(DateTime.now());

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TripInfoChip(
                expand: true,
                icon: Icons.calendar_today_rounded,
                label: _formatDate(b.departureTime),
                color: MyColors.primary,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TripInfoChip(
                expand: true,
                icon: Icons.access_time_rounded,
                label: _formatTime(b.departureTime),
                color: MyColors.accent,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
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
                  timeUntil(b.departureTime),
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
    );
  }

  // ━━━━━━━━━━━━━━━━ الأرقام ━━━━━━━━━━━━━━━━

  Widget _buildNumbers() {
    return Row(
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
    );
  }

  // ━━━━━━━━━━━━━━━━ أرقام التواصل ━━━━━━━━━━━━━━━━

  /// رقما التواصل: رقم السائق (للاتصال به) ورقم الراكب المسجَّل في هذا
  /// الحجز (ليعرف على أي رقم سيصله الاتصال). كلاهما يصل من الخادم ولم
  /// يكن يُعرض أيّ منهما.
  Widget _buildContacts() {
    final driverPhone = b.driverCommunicationNumber.trim();
    final myPhone = b.passengerCommunicationNumber.trim();
    if (driverPhone.isEmpty && myPhone.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.background,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MyColors.border, width: 1),
      ),
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
      showMySnackBar(context, 'تعذّر فتح تطبيق الاتصال');
    }
  }

  // ━━━━━━━━━━━━━━━━ تفاصيل ثانوية ━━━━━━━━━━━━━━━━

  Widget _buildMeta() {
    final isCash = b.paymentMethod.toLowerCase() == 'cash';

    return Row(
      children: [
        Expanded(
          child: TripInfoChip(
            expand: true,
            icon: Icons.directions_car_rounded,
            label: b.vehicleType.trim().isEmpty ? 'مركبة' : b.vehicleType,
            color: MyColors.textSecondary,
          ),
        ),
        SizedBox(width: 8.w),
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
        // حالة الرحلة لا يرسلها هذا المسار دائماً — تُخفى بدل عرض
        // مربّع «غير معروف»
        if (statusInfoRide.isKnown) ...[
          SizedBox(width: 8.w),
          Expanded(
            child: TripInfoChip(
              expand: true,
              icon: Icons.trip_origin_rounded,
              label: statusInfoRide.text,
              color: statusInfoRide.color,
            ),
          ),
        ],
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━ الإجراءات ━━━━━━━━━━━━━━━━

  Widget _buildActionArea() {
    return BlocBuilder<BookingMeCubit, BookingMeState>(
      builder: (context, state) {
        if (state is BookingMeButtonloading) {
          return SizedBox(
            height: 46.h,
            child: Center(
              child: SizedBox(
                width: 22.w,
                height: 22.w,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: MyColors.primary),
              ),
            ),
          );
        }
        if (state is BookingMeCanceled) {
          return MyButton(
            onPressed: () {},
            child: const Text("تم الغاء الحجز"),
          );
        }
        if (state is BookingMeRated) {
          return Center(
            child: RatingBarIndicator(
              rating: state.rate,
              itemBuilder: (context, index) =>
                  Icon(Icons.star_rounded, color: MyColors.warning),
              itemCount: 5,
              itemSize: 22.sp,
              unratedColor: MyColors.border,
            ),
          );
        }
        if (state is BookingMeWholeCanceled) {
          return MyButton(
            onPressed: () {},
            child: const Text("تم الغاء الحجز بالكامل"),
          );
        }
        if (state is BookingMeDriverNoShowReported) {
          return MyButton(
            onPressed: () {},
            child: const Text("تم تسجيل بلاغ عدم حضور السائق"),
          );
        }
        if (state is BookingMeFinish) {
          return _buildFeedBackButton(context, b.userDriver);
        }
        return _buildActionButtons(context, b.status, b.userDriver);
      },
    );
  }

  Widget _buildActionButtons(
      BuildContext context, String bookingState, int userId) {
    final now = DateTime.now();
    final departed = RideTimeRules.hasDeparted(b.departureTime, now: now);
    // البلاغ لا يُفتح مع انطلاق الرحلة بل بعد ساعة منه: سائق تأخّر
    // عشر دقائق ليس سائقاً غائباً، والبلاغ يخصم من نقاط ثقته.
    final canReport =
        RideTimeRules.canReportNoShow(b.departureTime, now: now);

    switch (bookingState) {
      case 'completed':
        return _Action(
          icon: Icons.star_rate_rounded,
          label: 'انتهت الرحلة — قيّم السائق',
          color: MyColors.accent,
          onTap: () => _showRatingDialog(context, userId),
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
        // الوصول، وبعد ساعة منه يُضاف بلاغ غياب السائق.
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
            // الكيوبت يُلتقط قبل الانتظار: استعمال context بعد فجوة غير
            // متزامنة يعتمد على بقاء الشجرة قائمة
            final cubit = context.read<BookingMeCubit>();
            final confirm = await _showConfirmationDialog(
              'تأكيدك يعني وصولك إلى وجهتك ونجاح الرحلة، وبه تكتمل '
              'الرحلة ويُحرَّر المبلغ للسائق.',
            );
            if (!(confirm ?? false) || !mounted) return;
            cubit.finishTrip(b.bookingId);
          },
        );

        // قبل مضيّ الساعة: التأكيد وحده ممتدّاً
        if (!canReport) return confirmAction;

        return Row(
          children: [
            Expanded(flex: 3, child: confirmAction),
            SizedBox(width: 8.w),
            Expanded(
              flex: 2,
              child: _Action(
                icon: Icons.report_problem_rounded,
                label: 'لم يحضر',
                color: MyColors.error,
                outlined: true,
                onTap: () async {
                  final cubit = context.read<BookingMeCubit>();
                  final confirm = await _showConfirmationDialog(
                    'هل أنت متأكد أن السائق لم يحضر؟ سيُسجَّل بلاغ '
                    'ويراجعه فريق الدعم.',
                  );
                  if (!(confirm ?? false) || !mounted) return;
                  cubit.reportDriverNoShow(b.rideId);
                },
              ),
            ),
          ],
        );
    }
  }

  Future<void> _askCancelSeats() async {
    final seatsToCancel = await _showCancelSeatsDialog();
    if (seatsToCancel == null || !mounted) return;

    final whole = seatsToCancel >= b.seats;
    final confirm = await _showConfirmationDialog(
      whole
          ? 'هل أنت متأكد من إلغاء الحجز بالكامل؟ قد يُخصم جزء من المبلغ '
              'حسب قربك من موعد الانطلاق.'
          : 'هل أنت متأكد من إلغاء $seatsToCancel مقعد؟ قد يُخصم جزء من '
              'المبلغ حسب قربك من موعد الانطلاق.',
    );
    if (!(confirm ?? false) || !mounted) return;
    _cancelSeats(seatsToCancel);
  }

  /// إلغاء كل المقاعد يمر عبر إلغاء الحجز الكامل، والجزئي عبر cancel-seats
  void _cancelSeats(int seatsToCancel) {
    final cubit = context.read<BookingMeCubit>();
    if (seatsToCancel >= widget.booking.seats) {
      cubit.cancelWholeBooking(widget.booking.bookingId);
    } else {
      cubit.cancelBooking(widget.booking.bookingId, seatsToCancel);
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  String _formatTime(DateTime time) {
    int hour = time.hour;
    String period = hour >= 12 ? 'م' : 'ص'; // ص = AM ، م = PM
    hour = hour % 12;
    if (hour == 0) hour = 12; // للتعامل مع منتصف الليل والظهيرة
    String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute $period";
  }

  String timeUntil(DateTime tripTime) {
    final now = DateTime.now();
    if (tripTime.isBefore(now)) {
      return "انطلقت الرحلة";
    }

    final difference = tripTime.difference(now);

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;

    String formatUnit(int value, String singular, String dual, String plural) {
      if (value == 1) {
        return '$value $singular';
      } else if (value == 2) {
        return '$value $dual';
      } else if (value >= 3 && value <= 10) {
        return '$value $plural';
      } else {
        return '$value $singular';
      }
    }

    List<String> parts = [];
    if (days > 0) {
      parts.add(formatUnit(days, "يوم", "يومين", "أيام"));
    }
    if (hours > 0) {
      parts.add(formatUnit(hours, "ساعة", "ساعتين", "ساعات"));
    }
    if (minutes > 0) {
      parts.add(formatUnit(minutes, "دقيقة", "دقيقتين", "دقائق"));
    }

    if (parts.isEmpty) {
      return "انطلقت الرحلة ";
    }

    return "باقٍ على الانطلاق: ${parts.join(" و ")}";
  }

  Future<int?> _showCancelSeatsDialog() async {
    int selectedSeats = 1;
    int maxSeats = widget.booking.seats;

    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 10,
                backgroundColor: MyColors.cardBg,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "إلغاء المقاعد",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: MyColors.primary,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close,
                                color: MyColors.textLight),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "حدد عدد المقاعد التي تريد إلغاء حجزها",
                        style: TextStyle(
                          fontSize: 14,
                          color: MyColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: MyColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // زر التقليل
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: selectedSeats <= 1
                                    ? MyColors.textHint
                                    : MyColors.accent,
                              ),
                              onPressed: selectedSeats <= 1
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedSeats--;
                                      });
                                    },
                            ),

                            // عدد المقاعد المختارة
                            Text(
                              "$selectedSeats",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: MyColors.primary,
                              ),
                            ),

                            // زر الزيادة
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: selectedSeats >= maxSeats
                                    ? MyColors.textHint
                                    : MyColors.accent,
                              ),
                              onPressed: selectedSeats >= maxSeats
                                  ? null
                                  : () {
                                      setState(() {
                                        selectedSeats++;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "الحد الأقصى للإلغاء: $maxSeats مقاعد",
                        style: TextStyle(
                          fontSize: 12,
                          color: MyColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: MyColors.primary,
                                side: BorderSide(color: MyColors.primary),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("تراجع"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  Navigator.of(context).pop(selectedSeats),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: MyColors.accent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("تأكيد الإلغاء"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _showConfirmationDialog(String message,
      {bool showPolicyLink = true}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "تأكيد",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (showPolicyLink) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Get.toNamed(RouteName.policy);
                },
                child: Text(
                  "تعرف على سياسية التطبيق",
                  style: TextStyle(
                    color: MyColors.accent,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          SizedBox(
            width: 100,
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.surfaceAlt,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "لا",
                style: TextStyle(color: MyColors.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: 40,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "نعم",
                style: TextStyle(color: MyColors.textOnDark),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedBackButton(BuildContext context, int userId) {
    const starCount = 5;
    final stars = List.generate(
      starCount,
      (index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          Icons.star_rate_rounded,
          size: 20,
          color: Colors.white,
        ),
      ),
    );

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
    ).copyWith(
      overlayColor:
          WidgetStateProperty.all(MyColors.accent.withOpacity(0.3)),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 60.w),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: LinearGradient(
            colors: [MyColors.warning, MyColors.accent],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: MyColors.accent.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _showRatingDialog(context, userId),
          style: buttonStyle, // استخدام النمط الذي أنشأناه
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: stars,
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, int userId) {
    double userRating = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'قيم السائق',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'كيف تقيم تجربتك مع السائق',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  RatingBar.builder(
                    initialRating: 0,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 28.0, // تم تصغير حجم النجوم
                    itemPadding: const EdgeInsets.symmetric(
                        horizontal: 2.0), // تم تقليل المسافة
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        userRating = rating;
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  if (userRating > 0)
                    Text(
                      'تقييمك: ${userRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // حجم نص أصغر
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (userRating > 0) {
                      _saveRating(userRating, userId);
                      Navigator.of(context).pop();
                      _showThankYouMessage(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyColors.accent,
                    foregroundColor: MyColors.textOnDark,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('إرسال التقييم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _saveRating(double rating, int userId) async {
    await context.read<BookingMeCubit>().reateUser(rating, userId);
  }

  void _showThankYouMessage(BuildContext context) {
    showMySnackBar(context, "شكرا لك على تقييمك ");
  }
}

// ━━━━━━━━━━━━━━━━━━━ لبنات محلّية ━━━━━━━━━━━━━━━━━━━

/// خانة رقمية داخل البطاقة — رقم فوق تسميته، بعرض متساوٍ مع أخواتها.
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
        Text(label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 12.sp)),
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

/// زرّ إجراء بشكل واحد لكل حالات البطاقة — والمعطّل يُقرأ معطّلاً.
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
      height: 46.h,
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(
                    color: color.withValues(alpha: 0.5), width: 1.2),
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
    return BlocBuilder<BookingMeCubit, BookingMeState>(
      // الحالات الأخرى (إلغاء، تقييم…) تُعيد بناء منطقة الأزرار لا هذه
      buildWhen: (_, curr) =>
          curr is BookingMeloading || curr is BookingMeOpenConversation,
      builder: (context, state) {
        return IconButton(
          tooltip: 'مراسلة السائق',
          visualDensity: VisualDensity.compact,
          constraints: BoxConstraints(minWidth: 38.w, minHeight: 38.w),
          padding: EdgeInsets.zero,
          onPressed: () => context.read<BookingMeCubit>().openChatWithDriver(
                userId: booking.userDriver,
                name: booking.driverName.trim().isEmpty
                    ? 'سائق الرحلة'
                    : booking.driverName,
                avatar: booking.driverAvatar,
              ),
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
      },
    );
  }
}
