import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:alatarekak/core/constant/imagesUrl.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/manger/cubit/booking_user_in_trip_cubit.dart';
import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';

// ═══════════════════════════════════════════════════════════════════════════
// ⚠️ معاينة مؤقتة — تُحذَف قبل الدمج
//
// الباك إند لا يرسل `bookings` في رد تفاصيل الرحلة بعد، فالشاشة تظهر فارغة
// دائماً ولا يمكن الحكم على شكلها. هذا العلم يعبّئ حجزَين وهميين **في وضع
// التطوير فقط وحين لا توجد حجوزات حقيقية**، لمعاينة التصميم لا أكثر.
//
// اجعله false — أو احذف المتغيّر ودالته — فور اعتماد الشكل.
// الاختبارات تطفئه في setUp لأنه يُبطل اختبار الحالة الفارغة.
// ═══════════════════════════════════════════════════════════════════════════
bool kPreviewSampleBookings = true;

List<BookingModel> _sampleBookings() => [
      BookingModel(
        id: 9001,
        userName: 'ليلى الحموي',
        userId: 501,
        avatar: null,
        rating: 4.6,
        seats: 2,
        status: 'pending',
        totaPrice: 14000,
        bookingat: '2026-08-16T21:52:11+00:00',
        numberPhone: '+963988626577',
      ),
      BookingModel(
        id: 9002,
        userName: 'عمر الأتاسي',
        userId: 502,
        avatar: null,
        rating: 0,
        seats: 1,
        status: 'confirmed',
        totaPrice: 7000,
        bookingat: '2026-08-16T19:14:38+00:00',
        numberPhone: '',
      ),
    ];

/// حجوزات الركّاب على رحلة السائق.
///
/// كانت البطاقة تبني الصورة والشارة والأسطر بنفسها بمقاسات ثابتة بلا `.sp`،
/// فتبدو الحجوزات بهوية مختلفة عن بطاقات الرحلة في «رحلاتي» والبحث. صارت
/// تستخدم لبنات [trip_card_parts] نفسها: الصورة والشارة والرقاقات.
class BookingUserINTrip extends StatefulWidget {
  const BookingUserINTrip({super.key});

  @override
  State<BookingUserINTrip> createState() => _BookingUserINTripState();
}

class _BookingUserINTripState extends State<BookingUserINTrip> {
  List<BookingModel> usersBooking = [];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is List<BookingModel>) usersBooking = args;

    // معاينة التصميم فقط — انظر التحذير أعلى الملف
    if (usersBooking.isEmpty && kDebugMode && kPreviewSampleBookings) {
      usersBooking = _sampleBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.background,
      // زرّ الرجوع صريح: الشاشة تُفتح بالدفع من تفاصيل الرحلة، وكانت
      // `automaticallyImplyLeading: false` باقية من أيام كونها تبويباً في
      // الرئيسية — فبقي المستخدم محتجزاً فيها بلا مخرج إلا زرّ النظام.
      // العيب نفسه أُصلح في الشاشة الأب من قبل.
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20.sp),
          onPressed: () => Get.back(),
          tooltip: 'رجوع',
        ),
        title: Text('حجوزات الرحلة',
            style:
                AppTextStyles.titleMedium.copyWith(color: MyColors.textOnDark)),
        centerTitle: true,
      ),
      // أخطاء الخادم (قبول/رفض/بلاغ) كانت صامتة — تُعرض كسناك بار معرّب
      body: BlocListener<BookingUserInTripCubit, BookingUserInTripState>(
        listener: (context, state) {
          if (state is BookingUserInTripErorr) {
            showMySnackBar(context, state.message);
          } else if (state is BookingUserInTripOpenConversation) {
            Get.toNamed(RouteName.chatScreen, arguments: {
              'conversationId': state.conversationId,
              'title': state.title ?? 'الراكب',
              'avatar': state.avatar,
            });
          }
        },
        child: usersBooking.isEmpty
            ? const _EmptyBookings()
            : ListView(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                children: [
                  _BookingsSummary(bookings: usersBooking),
                  SizedBox(height: 16.h),
                  for (int i = 0; i < usersBooking.length; i++)
                    StaggeredItem(
                      index: i,
                      child: _BookingCard(booking: usersBooking[i]),
                    ),
                ],
              ),
      ),
    );
  }
}

// ─── بطاقة الملخّص ────────────────────────────────────────────────────────────

/// ملخّص حجوزات الرحلة ببطاقة متدرّجة — النمط نفسه المستخدَم في بطاقة
/// «موعد الانطلاق» في شاشة تفاصيل الرحلة، وهي الشاشة الأب لهذه. كان
/// الملخّص سطراً عارياً لا يشبه شيئاً في التطبيق.
class _BookingsSummary extends StatelessWidget {
  final List<BookingModel> bookings;
  const _BookingsSummary({required this.bookings});

  @override
  Widget build(BuildContext context) {
    // الملغى لا يُحسب في المقاعد المشغولة
    const dead = {'cancelled', 'rejected', 'no_show'};
    final active =
        bookings.where((b) => !dead.contains(b.status.toLowerCase()));
    final seats = active.fold<int>(0, (sum, b) => sum + b.seats);
    final pending =
        bookings.where((b) => b.status.toLowerCase() == 'pending').length;

    return Container(
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
              Icon(Icons.people_alt_rounded,
                  color: MyColors.accent, size: 20.sp),
              SizedBox(width: 8.w),
              // مرن بدل `Spacer` وعرضٍ طبيعي: العنوان والشارة معاً يتجاوزان
              // عرض البطاقة على الشاشات الضيقة ومع تكبير خطّ النظام
              Expanded(
                child: Text(
                  'حجوزات رحلتك',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // الطلبات المعلّقة هي ما يحتاج قراراً — تُبرز وحدها
              if (pending > 0) ...[
                SizedBox(width: 8.w),
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: MyColors.accent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      _pendingLabel(pending),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            _countLabel(bookings.length),
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'بمجموع ${_seatsLabel(seats)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  String _countLabel(int n) {
    if (n == 1) return 'حجز واحد';
    if (n == 2) return 'حجزان';
    return '$n حجوزات';
  }

  String _seatsLabel(int n) {
    if (n == 0) return 'لا مقاعد مشغولة';
    if (n == 1) return 'مقعد واحد';
    if (n == 2) return 'مقعدين';
    if (n <= 10) return '$n مقاعد';
    return '$n مقعداً';
  }

  String _pendingLabel(int n) =>
      n == 1 ? 'طلب بانتظارك' : '$n طلبات بانتظارك';
}

// ─── بطاقة الحجز ──────────────────────────────────────────────────────────────

class _BookingCard extends StatelessWidget {
  final BookingModel booking;
  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingUserInTripCubit, BookingUserInTripState>(
      builder: (context, state) {
        // الحالة المحلية تسبق الخادم: البطاقة تنقلب فوراً بعد القبول/الرفض
        final status = (state is BookingUserInTripUpdated &&
                state.bookingId == booking.id)
            ? state.statusRide
            : booking.status;

        final isBusy =
            state is BookingUserInTripLoading && state.bookingId == booking.id;

        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: MyColors.surface,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: MyColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: MyColors.shadowLight,
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardHeader(booking: booking, status: status),
              SizedBox(height: 14.h),
              Divider(height: 1, thickness: 1, color: MyColors.divider),
              SizedBox(height: 14.h),
              _CardChips(booking: booking),
              SizedBox(height: 14.h),
              _CardActions(booking: booking, status: status, isBusy: isBusy),
            ],
          ),
        );
      },
    );
  }
}

/// الصورة والاسم والتقييم والشارة.
class _CardHeader extends StatelessWidget {
  final BookingModel booking;
  final String status;
  const _CardHeader({required this.booking, required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // TripAvatar المشترك: يملك بديلاً عند فشل التحميل، بخلاف الأيقونة
        // البيضاء السابقة التي كانت تختفي على خلفية فاتحة
        TripAvatar(
          avatar: booking.avatar,
          size: 48,
          onTap: () =>
              Get.toNamed(RouteName.profile, arguments: booking.userId),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.userName.trim().isEmpty ? 'راكب' : booking.userName,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 3.h),
              // التقييم يصل في النموذج ولم يكن يُعرض؛ والصفر يعني «لا تقييم
              // بعد» لا «تقييم سيّئ» — فيُكتب نصاً
              Row(
                children: [
                  Icon(
                    booking.rating > 0
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14.sp,
                    color: booking.rating > 0
                        ? MyColors.warning
                        : MyColors.textHint,
                  ),
                  SizedBox(width: 4.w),
                  // مرن: الاسم الطويل مع شارة حالة عريضة يضيّقان العمود
                  Flexible(
                    child: Text(
                      booking.rating > 0
                          ? booking.rating.toStringAsFixed(1)
                          : 'راكب جديد',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 11.sp,
                        color: MyColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        // الشارة المشتركة: تلوين شفاف بحدّ، لا تعبئة صمّاء تصرخ في البطاقة
        TripStatusBadge(status: status),
      ],
    );
  }
}

/// المقاعد والسعر والموعد ورقم التواصل — رقاقات بلبنة الرحلة نفسها.
class _CardChips extends StatelessWidget {
  final BookingModel booking;
  const _CardChips({required this.booking});

  @override
  Widget build(BuildContext context) {
    final bookedAt = DateTime.tryParse(booking.bookingat);
    final hasPhone = booking.numberPhone.trim().isNotEmpty;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TripInfoChip(
                expand: true,
                icon: Icons.event_seat_rounded,
                label: _seatsLabel(booking.seats),
                color: MyColors.success,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: TripInfoChip(
                expand: true,
                // كانت أيقونة الدولار على مبلغ بالليرة السورية
                icon: Icons.payments_rounded,
                label: Money.withCurrency(booking.totaPrice),
                color: MyColors.warning,
              ),
            ),
          ],
        ),
        if (bookedAt != null || hasPhone) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              if (bookedAt != null)
                Expanded(
                  child: TripInfoChip(
                    expand: true,
                    icon: Icons.calendar_today_rounded,
                    label: '${DateTimeUtils.arabicDate(bookedAt)} · '
                        '${DateTimeUtils.formatTime(bookedAt)}',
                    color: MyColors.primary,
                  ),
                ),
              // رقم التواصل قد لا يصل — يُخفى السطر بدل عرض رقم مُلفَّق
              if (hasPhone) ...[
                if (bookedAt != null) SizedBox(width: 8.w),
                Expanded(
                  child: TripInfoChip(
                    expand: true,
                    icon: Icons.phone_rounded,
                    label: booking.numberPhone,
                    color: MyColors.blue,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  String _seatsLabel(int seats) {
    if (seats <= 0) return 'مقاعد غير محدّدة';
    if (seats == 1) return 'مقعد واحد';
    if (seats == 2) return 'مقعدان';
    return '$seats مقاعد';
  }
}

// ─── الإجراءات ────────────────────────────────────────────────────────────────

class _CardActions extends StatelessWidget {
  final BookingModel booking;
  final String status;
  final bool isBusy;

  const _CardActions({
    required this.booking,
    required this.status,
    required this.isBusy,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return Center(
        child: LottieBuilder.asset(ImagesUrl.loadinglottie,
            width: 32.r, height: 32.r),
      );
    }

    switch (status.trim().toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: _FilledAction(
                label: 'قبول',
                icon: Icons.check_rounded,
                color: MyColors.success,
                onTap: () => context
                    .read<BookingUserInTripCubit>()
                    .acceptPassanger(booking.id),
              ),
            ),
            SizedBox(width: 10.w),
            // إجراء هدّام: محدَّد بالحدّ لا بالتعبئة فلا يُضغط سهواً
            Expanded(
              child: _OutlinedAction(
                label: 'رفض',
                icon: Icons.close_rounded,
                color: MyColors.error,
                onTap: () => context
                    .read<BookingUserInTripCubit>()
                    .rejectPassanger(booking.id),
              ),
            ),
          ],
        );

      case 'confirmed':
      case 'accepted':
        return Row(
          children: [
            Expanded(
              child: _FilledAction(
                label: 'مراسلة',
                icon: Icons.chat_bubble_outline_rounded,
                color: MyColors.primary,
                onTap: () => context
                    .read<BookingUserInTripCubit>()
                    .openChatWithPassenger(
                      userId: booking.userId,
                      name: booking.userName,
                      avatar: booking.avatar,
                    ),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _OutlinedAction(
                label: 'لم يحضر',
                icon: Icons.report_problem_outlined,
                color: MyColors.error,
                onTap: () => _confirmNoShow(context),
              ),
            ),
          ],
        );

      default:
        // الحالات المنتهية لا إجراء عليها — الشارة في الرأس تكفي، فلا
        // نكرّرها رقاقةً ثانية أسفل البطاقة
        return const SizedBox.shrink();
    }
  }

  Future<void> _confirmNoShow(BuildContext context) async {
    final cubit = context.read<BookingUserInTripCubit>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: MyColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: MyColors.error, size: 24.sp),
            SizedBox(width: 8.w),
            Text('تأكيد',
                style: AppTextStyles.titleMedium.copyWith(fontSize: 17.sp)),
          ],
        ),
        content: Text(
          'هل أنت متأكد أن الراكب لم يحضر؟ سيُسجَّل بلاغ بحقه.',
          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14.sp, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('لا',
                style: AppTextStyles.labelLarge.copyWith(
                    fontSize: 14.sp, color: MyColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text('نعم',
                style: TextStyle(
                    fontSize: 14.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm ?? false) cubit.passengerNoShow(booking.id);
  }
}

class _FilledAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FilledAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: _ActionLabel(label: label, icon: icon, color: Colors.white),
      ),
    );
  }
}

class _OutlinedAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _OutlinedAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44.h,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5), width: 1.2),
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: _ActionLabel(label: label, icon: icon, color: color),
      ),
    );
  }
}

/// أيقونة ونصّ مرنان — العنوان الطويل يُقصَّر بدل أن يفيض عن الزرّ.
class _ActionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionLabel({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16.sp, color: color),
        SizedBox(width: 6.w),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── الحالة الفارغة ───────────────────────────────────────────────────────────

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/noBooking.png',
              width: 240.w,
              height: 240.h,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20.h),
            Text(
              'لا توجد حجوزات بعد',
              style: AppTextStyles.titleMedium.copyWith(fontSize: 17.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              'سنُشعرك فوراً عندما يحجز راكب مقعداً في رحلتك.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13.sp,
                color: MyColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
