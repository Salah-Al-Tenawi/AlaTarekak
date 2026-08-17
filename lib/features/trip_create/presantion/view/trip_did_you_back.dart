import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/view/widget/trip_did_you_back_text_and_buttons.dart';

/// شاشة نجاح إنشاء الرحلة — وتخدم لحظتين:
///
/// * **الرحلة الأولى** (`reverseTripRoute == false`): تؤكّد النشر، تعرض ملخص
///   ما نُشر، ثم تعرض إنشاء رحلة العودة.
/// * **رحلة العودة** (`reverseTripRoute == true`): تؤكّد أن الرحلتين
///   منشورتان وتُنهي التدفّق.
///
/// كانت الشاشة أيقونةً كبيرة ونصاً واحداً، وحالة العودة زرّاً فيه صورة
/// سيارة **بلا أي نصّ** — فلا يعرف المستخدم ما نُشر ولا ما يفعله الزرّ.
/// صارت تتبع هوية بطاقات الرحلة: ترويسة متدرّجة، وبطاقة ملخّص بالمسار
/// نفسه المستخدَم في «رحلاتي» و«تفاصيل الرحلة».
class TripDidYouBack extends StatefulWidget {
  const TripDidYouBack({super.key});

  @override
  State<TripDidYouBack> createState() => _TripDidYouBackState();
}

class _TripDidYouBackState extends State<TripDidYouBack> {
  late final TripFrom? tripFrom;

  @override
  void initState() {
    super.initState();
    // شاشة نجاح لا يجوز أن تنهار على تحويل نوع — الرحلة نُشرت فعلاً
    final args = Get.arguments;
    tripFrom = args is TripFrom ? args : null;
  }

  @override
  Widget build(BuildContext context) {
    final trip = tripFrom;
    final isReturnTrip = trip?.reverseTripRoute ?? true;

    return Scaffold(
      backgroundColor: MyColors.background,
      body: Column(
        children: [
          _SuccessHeader(isReturnTrip: isReturnTrip),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InfoNote(
                    icon: isReturnTrip
                        ? Icons.done_all_rounded
                        : Icons.notifications_active_outlined,
                    color: MyColors.success,
                    bgColor: MyColors.successLight,
                    text: isReturnTrip
                        ? 'رحلتاك منشورتان الآن. سنُشعرك فوراً عند وصول أي حجز.'
                        : 'رحلتك ظاهرة للركّاب الآن. سنُشعرك فوراً عند وصول أي حجز.',
                  ),
                  if (trip != null) ...[
                    SizedBox(height: 24.h),
                    _SectionTitle(
                      title: isReturnTrip ? 'رحلة العودة' : 'ملخص رحلتك',
                    ),
                    SizedBox(height: 12.h),
                    _TripSummaryCard(tripFrom: trip),
                  ],
                  SizedBox(height: 24.h),
                  if (!isReturnTrip && trip != null)
                    TripDidYouBackTextAndButtons(tripFrom: trip)
                  else
                    TripFlowPrimaryButton(
                      label: 'العودة إلى الرئيسية',
                      icon: Icons.home_rounded,
                      color: MyColors.success,
                      onTap: () => Get.offAllNamed(RouteName.home),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── الترويسة ─────────────────────────────────────────────────────────────────

class _SuccessHeader extends StatelessWidget {
  final bool isReturnTrip;
  const _SuccessHeader({required this.isReturnTrip});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1B5E20), MyColors.success],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 28.h),
          child: Column(
            children: [
              Container(
                width: 76.r,
                height: 76.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35), width: 2),
                ),
                child: Icon(Icons.check_rounded,
                    color: Colors.white, size: 42.sp),
              )
                  .animate()
                  .scale(
                      duration: 350.ms,
                      begin: const Offset(0.6, 0.6),
                      curve: Curves.easeOutBack)
                  .fadeIn(duration: 250.ms),
              SizedBox(height: 16.h),
              Text(
                isReturnTrip
                    ? 'تم نشر رحلة العودة'
                    : 'تم نشر رحلتك بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isReturnTrip ? 'رحلتان منشورتان' : 'في انتظار الحجوزات',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بطاقة الملخّص ────────────────────────────────────────────────────────────

/// المسار والموعد والمقاعد والسعر — بلبنات بطاقة الرحلة نفسها، فتُقرأ
/// الرحلة هنا كما تُقرأ في «رحلاتي» بلا تفاوت بصري.
class _TripSummaryCard extends StatelessWidget {
  final TripFrom tripFrom;
  const _TripSummaryCard({required this.tripFrom});

  @override
  Widget build(BuildContext context) {
    final departure = DateTime.tryParse(tripFrom.date ?? '');

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: MyColors.border, width: 1),
        boxShadow: [
          BoxShadow(
              color: MyColors.shadowLight,
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TripLocationLine(
            icon: Icons.circle,
            iconColor: MyColors.primary,
            label: 'الانطلاق',
            text: tripFrom.startName ?? '—',
          ),
          const TripRouteConnector(),
          TripLocationLine(
            icon: Icons.location_pin,
            iconColor: MyColors.accent,
            label: 'الوجهة',
            text: tripFrom.endName ?? '—',
          ),
          SizedBox(height: 16.h),
          Divider(height: 1, thickness: 1, color: MyColors.divider),
          SizedBox(height: 16.h),
          if (departure != null) ...[
            Row(
              children: [
                Expanded(
                  child: TripInfoChip(
                    expand: true,
                    icon: Icons.calendar_today_rounded,
                    label: DateTimeUtils.arabicDate(departure),
                    color: MyColors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                TripInfoChip(
                  icon: Icons.access_time_rounded,
                  label: DateTimeUtils.formatTime(departure),
                  color: MyColors.accent,
                ),
              ],
            ),
            SizedBox(height: 8.h),
          ],
          Row(
            children: [
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: Icons.event_seat_rounded,
                  label: _seatsLabel(tripFrom.numberSeats),
                  color: MyColors.success,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TripInfoChip(
                  expand: true,
                  icon: Icons.monetization_on_rounded,
                  label: '${Money.withCurrency(tripFrom.price)} / راكب',
                  color: MyColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _seatsLabel(int seats) {
    if (seats <= 0) return 'المقاعد غير محدّدة';
    if (seats == 1) return 'مقعد واحد';
    if (seats == 2) return 'مقعدان';
    return '$seats مقاعد';
  }
}

// ─── لبنات مشتركة داخل الشاشة ────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: MyColors.accent,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.titleMedium.copyWith(fontSize: 16.sp)),
      ],
    );
  }
}

class _InfoNote extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String text;

  const _InfoNote({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 12.sp,
                color: MyColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// زرّ الإجراء الأساسي — بعرض البطاقة وارتفاع موحّد مع بقية الشاشات.
class TripFlowPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const TripFlowPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp),
            SizedBox(width: 8.w),
            // مرن لا ثابت: العنوان الطويل («نعم، أنشئ رحلة العودة») يتجاوز
            // عرض الزرّ على الشاشات الضيقة أو مع تكبير خطّ النظام
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
