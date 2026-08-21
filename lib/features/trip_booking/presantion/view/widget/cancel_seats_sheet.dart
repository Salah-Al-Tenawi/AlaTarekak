import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/my_colors.dart';
import 'package:alatarekak/core/them/text_style_app.dart';
import 'package:alatarekak/core/utils/class/cancel_policy.dart';
import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/core/utils/widgets/consequence_card.dart';
import 'package:alatarekak/core/utils/widgets/seats_stepper.dart';

/// إلغاء مقاعد من حجز — **خطوة واحدة لا خطوتين**.
///
/// كان حوارين متتاليين: أوّلهما يختار العدد وثانيهما يسأل «هل أنت
/// متأكد؟» بنصّ لا يتغيّر بما اختير. والسؤال المنفصل لا يضيف يقيناً حين
/// يكرّر ما قيل للتوّ؛ الأنفع أن يرى المستخدم **أثر اختياره** قبل أن
/// يضغط — كم مقعداً يبقى له، ومتى يصير الإلغاء كاملاً.
///
/// والعدّاد هو [SeatsStepper] المشترك: كان الحوار يبني زرَّي زيادة ونقص
/// بنفسه بمقاسات ثابتة، فبدا عدّاداً ثالثاً في تطبيق فيه عدّاد واحد.
class CancelSeatsSheet extends StatefulWidget {
  /// مقاعد الحجز كلها — الحدّ الأعلى للإلغاء.
  final int bookedSeats;

  /// سعر المقعد — لعرض ما يُلغى من قيمة الحجز.
  final double pricePerSeat;

  /// نسبة ما انقضى من عمر الحجز — تُحسب منها كلفة الإلغاء. `null` حين
  /// يتعذّر حسابها، فتُعرض جملة عامّة بدل رقم مخترع.
  final double? elapsedPercent;

  /// الرحلة نقدية: لا استرداد أصلاً، والنقاط تُخصم.
  final bool cashRide;

  const CancelSeatsSheet({
    super.key,
    required this.bookedSeats,
    required this.pricePerSeat,
    this.elapsedPercent,
    this.cashRide = false,
  });

  /// يفتحها ويُعيد عدد المقاعد المطلوب إلغاؤها — `null` إن تراجع.
  static Future<int?> show(
    BuildContext context, {
    required int bookedSeats,
    required double pricePerSeat,
    double? elapsedPercent,
    bool cashRide = false,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: MyColors.navy.withValues(alpha: 0.45),
      builder: (_) => CancelSeatsSheet(
        bookedSeats: bookedSeats,
        pricePerSeat: pricePerSeat,
        elapsedPercent: elapsedPercent,
        cashRide: cashRide,
      ),
    );
  }

  @override
  State<CancelSeatsSheet> createState() => _CancelSeatsSheetState();
}

class _CancelSeatsSheetState extends State<CancelSeatsSheet> {
  int _seats = 1;

  bool get _isWholeBooking => _seats >= widget.bookedSeats;
  int get _remaining => widget.bookedSeats - _seats;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MyColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26.r)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _grabHandle()),
              SizedBox(height: 16.h),
              _header(),
              SizedBox(height: 18.h),
              // حجز بمقعد واحد لا خيار فيه: العدّاد محبوس على 1 فيُخفى،
              // ويبقى النصّ يقول إن الإلغاء كامل.
              if (widget.bookedSeats > 1) ...[
                SeatsStepper(
                  value: _seats,
                  min: 1,
                  max: widget.bookedSeats,
                  label: 'مقاعد تُلغى',
                  icon: Icons.event_busy_rounded,
                  onChanged: (value) => setState(() => _seats = value),
                ),
                SizedBox(height: 12.h),
              ],
              _outcome(),
              SizedBox(height: 12.h),
              _refundNotice(),
              SizedBox(height: 18.h),
              _actions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _grabHandle() => Container(
        width: 44.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: MyColors.border,
          borderRadius: BorderRadius.circular(4.r),
        ),
      );

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: MyColors.error.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.event_busy_rounded,
              color: MyColors.error, size: 22.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إلغاء الحجز',
                  style: AppTextStyles.titleMedium.copyWith(fontSize: 16.sp)),
              SizedBox(height: 2.h),
              Text(
                'لديك ${_seatsWord(widget.bookedSeats)} في هذه الرحلة',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 12.5.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// **أثر الاختيار** — ما كان الحوار المنفصل يسأل عنه بلا أن يقوله.
  Widget _outcome() {
    final color = _isWholeBooking ? MyColors.error : MyColors.warning;
    final text = _isWholeBooking
        ? 'يُلغى الحجز بالكامل، ولا يبقى لك مقعد في هذه الرحلة'
        : 'يبقى لك ${_seatsWord(_remaining)} بعد الإلغاء';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Icon(
            _isWholeBooking
                ? Icons.warning_amber_rounded
                : Icons.info_outline_rounded,
            size: 18.sp,
            color: color,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: MyColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _refundNotice() {
    final value = widget.pricePerSeat * _seats;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: MyColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: MyColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (value > 0)
            Row(
              children: [
                Icon(Icons.payments_rounded,
                    size: 16.sp, color: MyColors.textSecondary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text('قيمة ما يُلغى',
                      style:
                          AppTextStyles.bodySmall.copyWith(fontSize: 12.5.sp)),
                ),
                Text(
                  Money.withCurrency(value),
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.bold,
                    color: MyColors.textPrimary,
                  ),
                ),
              ],
            ),
          if (value > 0) SizedBox(height: 10.h),
          // **الكلفة تُحسب لا تُوصف.** كانت جملة واحدة — «قد يُخصم جزء من
          // المبلغ حسب قربك من موعد الانطلاق» — تُقال لمن يُعاد إليه كل
          // مبلغه ولمن لا يُعاد إليه شيء سواءً بسواء.
          ConsequenceCard(
            lines: CancelPolicy.passengerCancel(
              elapsed: widget.elapsedPercent,
              amount: value.round(),
              cashRide: widget.cashRide,
            ),
          ),
          SizedBox(height: 8.h),
          GestureDetector(
            onTap: () => Get.toNamed(RouteName.policy),
            child: Text(
              'اطّلع على سياسة الإلغاء',
              style: TextStyle(
                fontSize: 12.sp,
                color: MyColors.accent,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: MyColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48.h,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: MyColors.textSecondary,
                side: BorderSide(color: MyColors.border, width: 1.2),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text('تراجع',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48.h,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(_seats),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyColors.error,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r)),
              ),
              child: Text(
                _isWholeBooking ? 'إلغاء الحجز' : 'إلغاء ${_seatsWord(_seats)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// «مقعد» و«مقعدان» و«3 مقاعد» — لا «1 مقاعد».
  String _seatsWord(int seats) {
    if (seats == 1) return 'مقعداً واحداً';
    if (seats == 2) return 'مقعدين';
    return '$seats مقاعد';
  }
}
