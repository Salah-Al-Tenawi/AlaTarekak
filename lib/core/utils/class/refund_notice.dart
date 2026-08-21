import 'package:alatarekak/core/utils/class/format_money.dart';
import 'package:alatarekak/features/trip_booking/data/model/cancel_booking_model.dart';

/// ما يُقال للراكب بعد إلغائه مقاعد من حجزه.
///
/// **ثلاثة أفخاخ في ردٍّ واحد**، ولا يقي منها إلا فحص حال الحجز قبل
/// قراءة أرقامه:
///
///   ١. `refund_percentage` ليست مبلغاً. كانت تُعرض «تم استرداد 70 ل.س»
///      على استردادٍ قدره أربعة عشر ألفاً — الرقم الصحيح `refund_amount`.
///
///   ٢. الحجز المعلَّق (`pending`) يصله `refund_policy` كاملاً **ولم
///      يُنفَّذ منه شيء**: العمليات المالية كلها داخل `if (wasConfirmed)`
///      عند الخادم. فعرضه يَعِد الراكب بمالٍ لم يدفعه أصلاً.
///
///   ٣. الرحلة النقدية لا حركة مالية فيها البتّة — الدفع يقع للسائق يداً
///      بيد، فلا استرداد مهما قالت النسبة.
///
/// دالّة نقيّة، تُختبر بلا واجهة ولا شبكة.
String refundNotice(
  RefundPolicy policy, {
  required bool wasConfirmed,
  required bool cashRide,
}) {
  if (!wasConfirmed) {
    return 'لم يُخصم منك مبلغ: الحجز كان بانتظار موافقة السائق، '
        'فلا استرداد ولا خصم نقاط.';
  }

  if (cashRide) {
    return 'الدفع في هذه الرحلة نقديّ للسائق، فلا مبالغ مستردّة.';
  }

  if (policy.refundAmount <= 0) {
    return 'لا مبلغ مسترد: مضى من وقت الرحلة ما يُسقط الاسترداد.';
  }

  final percentage = policy.refundPercentage;
  final amount = Money.withCurrency(policy.refundAmount.round());

  return percentage > 0 && percentage < 100
      ? 'أُعيد إليك $amount — ${percentage.round()}% من قيمة المقاعد الملغاة.'
      : 'أُعيد إليك $amount كاملاً.';
}
