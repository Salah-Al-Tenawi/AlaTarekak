import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/animations/app_animations.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/them/app_snack_bar.dart';
import 'package:alatarekak/core/utils/functions/show_my_snackbar.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/core/service/no_show_report_store.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';
import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/core/utils/widgets/app_loader.dart';
import 'package:alatarekak/core/utils/widgets/no_show_gate.dart';
import 'package:alatarekak/core/utils/widgets/rate_user_sheet.dart';
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

  /// موعد انطلاق الرحلة — يحدّد متى يظهر بلاغ «لم يحضر». غيابه يعني
  /// أننا لا نعرف الموعد، فلا نُظهر البلاغ إطلاقاً: بلاغ بلا موعد قد
  /// يُرسَل قبل أن تبدأ الرحلة.
  DateTime? departure;

  /// معرّف الرحلة — بدونه لا تستطيع الشاشة الجلب بنفسها.
  int? rideId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    // الشكل الحالي خريطة تحمل معرّف الرحلة وموعدها؛ والقائمة المجرّدة
    // تُقبل أيضاً لأن الشاشة مسار مسمّى قد يُنادى من إشعار أو رابط قديم.
    if (args is Map) {
      final list = args['bookings'];
      if (list is List<BookingModel>) usersBooking = list;
      final at = args['departure'];
      if (at is DateTime) departure = at;
      rideId = args['rideId'] is int ? args['rideId'] as int : null;
    } else if (args is List<BookingModel>) {
      usersBooking = args;
    }

    // **الشاشة تجلب بنفسها.** ما يصلها من شاشة التفاصيل يُعرض فوراً، ثم
    // يستبدله `GET /rides/{id}/passengers` — المسار الموضوع لهذا الغرض.
    // كانت تعتمد كلياً على ما مرّرته الشاشة السابقة، فتظهر فارغة إن لم
    // يُرسل `GET /rides/{id}` الحجوزات، ولا تتحدّث بعد قبول أو رفض.
    final id = rideId;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<BookingUserInTripCubit>().loadBookings(id);
      });
    }

    // معاينة التصميم فقط — انظر التحذير أعلى الملف
    if (usersBooking.isEmpty && kDebugMode && kPreviewSampleBookings) {
      usersBooking = _sampleBookings();
    }
  }

  /// التعارض ليس سناك بار — انظر نظيرتها في شاشة «حجوزاتي».
  ///
  /// حين يبلّغ الطرفان كلٌّ عن غياب الآخر لا عقوبة تلقائية، بل شكوى
  /// يبتّ فيها الدعم. **والسائق لا يراها في `GET /complaints`**: الشكوى
  /// تُنسب إلى الراكب وحده، فجلبها برقمها يردّ 404. فالإشعار
  /// `noshow_conflict` هو طريق السائق إليها، وهذا الحوار يخبره بها.
  void _onNoShowReported(
      BuildContext context, BookingUserInTripNoShowReported state) {
    if (state.outcome != NoShowOutcome.conflict) {
      showMySnackBar(context, state.message, type: SnackType.success);
      return;
    }

    showAppDialog(
      context,
      icon: Icons.gavel_rounded,
      title: 'تعارض في البلاغات',
      message: state.message,
      accentColor: MyColors.warning,
    );
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
            showMySnackBar(context, state.message, type: SnackType.error);
          } else if (state is BookingUserInTripNoShowReported) {
            _onNoShowReported(context, state);
            // الحالة الناتجة `no_show` تصل مع القائمة، والعدّادات في
            // الأعلى تُحسب منها
            final id = rideId;
            if (id != null) {
              context
                  .read<BookingUserInTripCubit>()
                  .loadBookings(id, silent: true);
            }
          } else if (state is BookingUserInTripRated) {
            showMySnackBar(context, 'شكراً لك على تقييمك',
                type: SnackType.success);
          } else if (state is BookingUserInTripOpenConversation) {
            Get.toNamed(RouteName.chatScreen, arguments: {
              'conversationId': state.conversationId,
              'title': state.title ?? 'الراكب',
              'avatar': state.avatar,
            });
          } else if (state is BookingUserInTripListLoaded) {
            // ما جلبته الشاشة يحلّ محلّ ما مُرّر إليها
            setState(() {
              usersBooking = state.bookings;
              departure = state.departure;
            });
          } else if (state is BookingUserInTripUpdated) {
            // قبول أو رفض غيّر الحالة على الخادم: العدّادات في الأعلى
            // تُحسب من القائمة، فتبقى قديمة بلا إعادة جلب
            final id = rideId;
            if (id != null) {
              context
                  .read<BookingUserInTripCubit>()
                  .loadBookings(id, silent: true);
            }
          }
        },
        child: BlocBuilder<BookingUserInTripCubit, BookingUserInTripState>(
          buildWhen: (_, current) =>
              current is BookingUserInTripFetching ||
              current is BookingUserInTripListLoaded ||
              current is BookingUserInTripErorr,
          builder: (context, state) {
            if (state is BookingUserInTripFetching && usersBooking.isEmpty) {
              return const Center(child: AppLoader());
            }

            if (usersBooking.isEmpty) return const _EmptyBookings();

            return RefreshIndicator(
              onRefresh: () async {
                final id = rideId;
                if (id != null) {
                  await context
                      .read<BookingUserInTripCubit>()
                      .loadBookings(id, silent: true);
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 20.h),
                children: [
                  _BookingsSummary(bookings: usersBooking),
                  SizedBox(height: 16.h),
                  for (int i = 0; i < usersBooking.length; i++)
                    StaggeredItem(
                      index: i,
                      child: _BookingCard(
                        booking: usersBooking[i],
                        departure: departure,
                      ),
                    ),
                ],
              ),
            );
          },
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
  final DateTime? departure;

  const _BookingCard({required this.booking, this.departure});

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
              _CardActions(
                booking: booking,
                status: status,
                isBusy: isBusy,
                departure: departure,
              ),
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
  /// موعد انطلاق الرحلة — بلاغ عدم الحضور لا يظهر قبل مضيّ
  /// [RideTimeRules.noShowDelay] عليه.
  final DateTime? departure;

  final BookingModel booking;
  final String status;
  final bool isBusy;

  const _CardActions({
    required this.booking,
    required this.status,
    required this.isBusy,
    this.departure,
  });

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      // اثنتان وثلاثون نقطة: دون حدّ قراءة الطريق، فيُرسم الدوّار
      return const Center(child: AppLoader(size: 32));
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
        // البلاغ لا يُفتح إلا بعد ساعة من الانطلاق: التأخّر نصف ساعة
        // زحمة سير لا غياب، والبلاغ يخصم من نقاط ثقة الراكب.
        final canReport = departure != null &&
            RideTimeRules.canReportNoShow(departure!);

        final chat = _FilledAction(
          label: 'مراسلة',
          icon: Icons.chat_bubble_outline_rounded,
          color: MyColors.primary,
          onTap: () =>
              context.read<BookingUserInTripCubit>().openChatWithPassenger(
                    userId: booking.userId,
                    name: booking.userName,
                    avatar: booking.avatar,
                  ),
        );

        // موعد مجهول: لا نعرض بلاغاً قد يقع قبل أوانه — انظر [departure]
        if (departure == null) return chat;

        return Row(
          children: [
            Expanded(child: chat),
            SizedBox(width: 10.w),
            Expanded(child: _noShowAction(context, canReport: canReport)),
          ],
        );

      // الرحلة تمّت — يُتاح للسائق تقييم راكبه.
      //
      // `completed` هي حالة الحجز بعد أن يؤكّد الراكب وصوله، و`finished`
      // بعد أن يُنهي السائق رحلته. كلتاهما تعني «انتهى اللقاء»، وقبلهما
      // لا معنى لتقييم لقاء لم يقع بعد.
      case 'completed':
      case 'finished':
        return _FilledAction(
          label: 'قيّم الراكب',
          icon: Icons.star_rate_rounded,
          color: MyColors.accent,
          onTap: () => _rate(context),
        );

      default:
        // الملغاة وغير الحاضر لا إجراء عليها — الشارة في الرأس تكفي،
        // فلا نكرّرها رقاقةً ثانية أسفل البطاقة
        return const SizedBox.shrink();
    }
  }

  /// تقييم الراكب — الورقة المشتركة نفسها التي يقيّم بها الراكبُ سائقَه.
  Future<void> _rate(BuildContext context) async {
    final cubit = context.read<BookingUserInTripCubit>();
    final name = booking.userName.trim().isEmpty ? 'الراكب' : booking.userName;

    final result = await RateUserSheet.show(
      context,
      name: name,
      question: 'كيف كان $name راكباً؟',
      avatar: booking.avatar,
    );
    if (result == null) return;

    cubit.ratePassenger(result.rating, booking.userId,
        comment: result.comment);
  }

  /// زرّ «لم يحضر» بأحواله الثلاثة — كما في جانب الراكب.
  ///
  /// **لا يُخفى قبل أوانه بل يُعطَّل ومعه ما بقي**: السائق الذي انتظر
  /// راكباً يبحث عن الإبلاغ، وغيابُ الزرّ يوهمه أن التطبيق لا يتيحه.
  /// والمُبلَّغ عنه سابقاً يُعطَّل — الحالة محلية لأن الخادم لا يكشف
  /// تقارير الغياب في أي مسار.
  Widget _noShowAction(BuildContext context, {required bool canReport}) {
    if (NoShowReportStore.wasReported(
        NoShowReportStore.bookingKey(booking.id))) {
      return _OutlinedAction(
        label: 'تم الإبلاغ',
        icon: Icons.flag_rounded,
        color: MyColors.textSecondary,
        onTap: null,
      );
    }

    // العدّاد حيّ: يُعيد بناء نفسه كل دقيقة، ثم يفتح الزرّ عند انقضاء
    // المهلة بلا أن يغادر السائق الشاشة ويعود.
    return NoShowGate(
      departure: departure!,
      builder: (context, remaining) {
        if (remaining != null) {
          return _OutlinedAction(
            label: noShowCountdownLabel(remaining),
            icon: Icons.schedule_rounded,
            color: MyColors.textSecondary,
            onTap: null,
          );
        }
        return _OutlinedAction(
          label: 'لم يحضر',
          icon: Icons.report_problem_outlined,
          color: MyColors.error,
          onTap: () => _confirmNoShow(context),
        );
      },
    );
  }

  Future<void> _confirmNoShow(BuildContext context) async {
    final cubit = context.read<BookingUserInTripCubit>();
    final confirm = await showAppDialog(
      context,
      icon: Icons.report_problem_outlined,
      title: 'الراكب لم يحضر؟',
      message: 'سيُسجَّل بلاغ بحقّ ${booking.userName}، وله ساعتان '
          'للاعتراض قبل أن يُحسم تلقائياً وتُخصم من نقاط ثقته. '
          'لا تُرسله إلا بعد انتظاره فعلاً.',
      confirmLabel: 'تسجيل البلاغ',
      cancelLabel: 'تراجع',
      destructive: true,
    );

    if (confirm == true) cubit.passengerNoShow(booking.id);
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

  /// `null` يعرض الزرّ معطّلاً — لبلاغ لم يحن أوانه أو سبق تسجيله.
  final VoidCallback? onTap;

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
