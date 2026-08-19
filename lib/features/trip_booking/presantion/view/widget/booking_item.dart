import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/format_date_time.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/widgets/trip_card_parts.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_status_filter.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_time_text.dart';

/// بطاقة حجز في «حجوزاتي» — **ملخّص لا ملفّ**.
///
/// كانت البطاقة تعرض كل ما يصل من الخادم: المسار والموعد والعدّاد وثلاث
/// خانات رقمية ورقمَي تواصل ونوع المركبة وطريقة الدفع وحالة الرحلة وزرّ
/// الإجراء — فبلغ ارتفاعها شاشة كاملة، وصار على من له خمسة حجوزات أن
/// يمرّر خمس شاشات ليرى ما عنده.
///
/// الآن ستّ معلومات تكفي للتعرّف على الحجز: السائق، حالته، المسار،
/// الموعد، المقاعد، والإجمالي. والباقي — مع كل الإجراءات — في
/// `BookingDetailsSheet` عند الضغط.
class BookingItem extends StatelessWidget {
  final BookingMe booking;

  /// يفتح ورقة التفاصيل. تُمرَّر من الشاشة لا تُستدعى هنا، ليبقى عرض
  /// البطاقة مستقلاً عمّا يحدث عند الضغط.
  final VoidCallback onTap;

  const BookingItem({
    super.key,
    required this.booking,
    required this.onTap,
  });

  BookingMe get b => booking;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20.r);

    return Card(
      elevation: 2,
      shadowColor: MyColors.shadowMedium,
      color: MyColors.surface,
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: MyColors.border, width: 1),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              SizedBox(height: 10.h),
              Divider(height: 1, color: MyColors.divider),
              SizedBox(height: 10.h),
              _route(),
              SizedBox(height: 12.h),
              _facts(),
              ..._countdown(),
            ],
          ),
        ),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━ الرأس ━━━━━━━━━━━━━━━━

  Widget _header() {
    return Row(
      children: [
        TripAvatar(avatar: b.driverAvatar, size: 42),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                b.driverName.trim().isEmpty ? 'سائق الرحلة' : b.driverName,
                style: AppTextStyles.bodyLarge
                    .copyWith(fontSize: 14.5.sp, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                'حجز رقم ${b.bookingId}',
                style: AppTextStyles.labelSmall.copyWith(fontSize: 11.sp),
              ),
            ],
          ),
        ),
        SizedBox(width: 6.w),
        TripStatusBadge(status: b.status),
        SizedBox(width: 2.w),
        // إشارة أن للبطاقة عمقاً — بلا زرّ «تفاصيل» يأكل سطراً كاملاً.
        // الأيقونة تنعكس مع اتجاه النصّ فتشير يساراً في الواجهة العربية.
        Icon(Icons.arrow_forward_ios_rounded,
            size: 13.sp, color: MyColors.textHint),
      ],
    );
  }

  // ━━━━━━━━━━━━━━━━ المسار ━━━━━━━━━━━━━━━━

  /// المسار في سطر واحد بدل سطرين وخيط بينهما: البطاقة ملخّص، والتفصيل
  /// المصوّر في الورقة.
  Widget _route() => TripRouteRow(
        from: b.pickupAddress,
        to: b.destinationAddress,
      );

  // ━━━━━━━━━━━━━━━━ الأرقام ━━━━━━━━━━━━━━━━

  /// موعد ومقاعد وإجمالي في سطر واحد.
  ///
  /// كانت رقاقات كاملة الحدود، فبلغ عرض رقاقة الموعد وحدها عرض السطر
  /// ونزل الباقي سطرين تحتها. الموعد والمقاعد صارا نصّاً بأيقونته —
  /// والرقاقة تبقى للإجمالي وحده لأنه الرقم الذي يُبحث عنه.
  ///
  /// الطرفان مرنان بقصّ لطيف، والرقاقة تأخذ عرض محتواها: فلا يفيض السطر
  /// مهما طال الموعد أو كبر المبلغ.
  Widget _facts() {
    return Row(
      children: [
        Flexible(
          flex: 3,
          child: TripFactLine(
            icon: Icons.calendar_today_rounded,
            text: _departureLabel(),
            color: MyColors.primary,
          ),
        ),
        SizedBox(width: 10.w),
        Flexible(
          flex: 2,
          child: TripFactLine(
            icon: Icons.event_seat_rounded,
            text: '${b.seats} مقعد',
            color: MyColors.success,
          ),
        ),
        SizedBox(width: 8.w),
        _PricePill(total: b.totalPrice),
      ],
    );
  }

  /// «20/08 · 12:18 ص» — السنة تُذكر حين تختلف عن السنة الجارية فقط.
  /// حجوزات هذا العام هي الغالبة، وذكر «2026» فيها كلها ضجيج يزاحم
  /// المقاعد والإجمالي على السطر نفسه.
  String _departureLabel() {
    final departure = b.departureTime;
    final date = departure.year == DateTime.now().year
        ? '${departure.day.toString().padLeft(2, '0')}/'
            '${departure.month.toString().padLeft(2, '0')}'
        : DateTimeUtils.formatDate(departure);

    return '$date · ${DateTimeUtils.formatTime(departure)}';
  }

  // ━━━━━━━━━━━━━━━━ العدّاد ━━━━━━━━━━━━━━━━

  /// «باقٍ على الانطلاق» — يظهر للحجوزات القائمة وحدها. عرضه على حجز ملغى
  /// أو رحلة انتهت ضجيج، وعلى موعد مضى كذب.
  List<Widget> _countdown() {
    if (!_isUpcoming) return const [];
    final remaining = remainingUntilDeparture(b.departureTime);
    if (remaining == null) return const [];

    return [
      SizedBox(height: 10.h),
      Row(
        children: [
          Icon(Icons.schedule_rounded, size: 13.sp, color: MyColors.warning),
          SizedBox(width: 5.w),
          Expanded(
            child: Text(
              'باقٍ على الانطلاق: $remaining',
              style: TextStyle(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: MyColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ];
  }

  /// الحجز قائم — طلبٌ ينتظر ردّاً أو حجزٌ مؤكَّد. مصدر التصنيف واحد مع
  /// شريط الرقاقات، فحالة جديدة من الخادم تُضاف في موضع واحد.
  bool get _isUpcoming =>
      BookingStatusFilter.pending.matches(b.status) ||
      BookingStatusFilter.confirmed.matches(b.status);
}

// ━━━━━━━━━━━━━━━━━━━ لبنات محلّية ━━━━━━━━━━━━━━━━━━━

/// الإجمالي — الرقم الوحيد الذي يستحق وزناً بصرياً أعلى في الملخّص.
class _PricePill extends StatelessWidget {
  final int total;

  const _PricePill({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: MyColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
            color: MyColors.accent.withValues(alpha: 0.28), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.payments_rounded, size: 13.sp, color: MyColors.accent),
          SizedBox(width: 5.w),
          Text(
            Money.withCurrency(total),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: MyColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
