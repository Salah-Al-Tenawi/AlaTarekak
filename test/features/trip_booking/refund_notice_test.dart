import 'package:alatarekak/core/utils/class/refund_notice.dart';
import 'package:alatarekak/features/trip_booking/data/model/cancel_booking_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما يُقال للراكب بعد إلغاء مقاعده — ثلاثة أفخاخ في ردّ واحد.
///
/// ردّ `POST /bookings/{id}/cancel-seats` الحقيقي، من مواصفة الباك إند:
/// نسبة ومبلغ معاً، ويصل كاملاً حتى للحجز المعلَّق الذي لم يُدفع عنه شيء.
RefundPolicy _policy({
  double percentage = 70,
  double amount = 14000,
  double nonRefundable = 6000,
}) =>
    RefundPolicy.fromJson({
      'refund_percentage': percentage,
      'refund_amount': amount,
      'non_refundable_amount': nonRefundable,
      'time_elapsed_percentage': 42.15,
      'policy_tier': 'Partial refund (30-50% elapsed)',
    });

void main() {
  group('المبلغ لا النسبة — العطب المُصلَح', () {
    test('يُعرض 14,000 لا 70', () {
      final text = refundNotice(_policy(), wasConfirmed: true, cashRide: false);

      expect(text, contains('14,000 ل.س'),
          reason: 'كانت الرسالة «تم استرداد 70 ل.س» على استرداد قدره '
              'أربعة عشر ألفاً');
      expect(text, isNot(contains('70 ل.س')));
    });

    test('والنسبة تبقى سياقاً لا مبلغاً', () {
      expect(refundNotice(_policy(), wasConfirmed: true, cashRide: false),
          contains('70%'));
    });

    test('الاسترداد الكامل يُقال كاملاً بلا نسبة', () {
      final text = refundNotice(_policy(percentage: 100, amount: 20000),
          wasConfirmed: true, cashRide: false);

      expect(text, contains('20,000 ل.س'));
      expect(text, isNot(contains('100%')));
    });
  });

  group('حالات لا مال فيها', () {
    test('حجز معلَّق: لا وعد بمال لم يُدفع', () {
      final text =
          refundNotice(_policy(), wasConfirmed: false, cashRide: false);

      expect(text, contains('بانتظار موافقة السائق'));
      expect(text, isNot(contains('14,000')),
          reason: 'الخادم يرسل refund_policy للمعلَّق ولا ينفّذ منه شيئاً');
    });

    test('رحلة نقدية: لا استرداد مهما قالت النسبة', () {
      final text = refundNotice(_policy(), wasConfirmed: true, cashRide: true);

      expect(text, contains('نقديّ'));
      expect(text, isNot(contains('14,000')));
    });

    test('بعد الانطلاق: صفرٌ يُقال بالكلمات لا بالرقم', () {
      final text = refundNotice(
          _policy(percentage: 0, amount: 0, nonRefundable: 20000),
          wasConfirmed: true,
          cashRide: false);

      expect(text, contains('لا مبلغ مسترد'));
      expect(text, isNot(contains('0 ل.س')));
    });
  });
}
