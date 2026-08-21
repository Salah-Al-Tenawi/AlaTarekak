import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/utils/class/no_show_report.dart';
import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// قراءة ردّ بلاغ الغياب.
///
/// الخادم لا يقول في حقل صريح أيّ نهاية وقعت: الكونترولر يُسقط
/// `conflict` و`report_id` و`expires_at` و`complaint_id` رغم أن الخدمة
/// تُرجعها. فالتمييز من نصّ الرسالة — حلٌّ التفافي مؤقّت جُمع في موضع
/// واحد ليُحذف من موضع واحد.
void main() {
  group('التعارض — يصل 200 كالنجاح، ونصّه وحده يميّزه', () {
    const conflictMessage =
        'Both parties filed a no-show report. A support complaint has been '
        'opened automatically. No automatic penalty will be applied — the '
        'support team will investigate.';
    const normalMessage =
        'No-show report submitted. The driver has 2 hours to dispute. If no '
        'dispute, the penalty is applied automatically.';

    test('ردّ التعارض يُقرأ تعارضاً', () {
      expect(
        NoShowReport.isConflict({'status': 'success', 'message': conflictMessage}),
        isTrue,
      );
    });

    test('الردّ العادي ليس تعارضاً', () {
      expect(
        NoShowReport.isConflict({'status': 'success', 'message': normalMessage}),
        isFalse,
      );
    });

    test('نصّ المسارين واحد — بلاغ السائق كبلاغ الراكب', () {
      const driverSide =
          'No-show report submitted. The passenger has 2 hours to dispute. '
          'If no dispute, the penalty is applied automatically.';

      expect(NoShowReport.isConflict({'message': driverSide}), isFalse);
    });

    test('ردّ ليس خريطة لا يرمي', () {
      expect(NoShowReport.isConflict(null), isFalse);
      expect(NoShowReport.isConflict('Both parties filed…'), isTrue);
      expect(NoShowReport.isConflict(42), isFalse);
    });

    test('خريطة بلا رسالة لا تُقرأ تعارضاً', () {
      expect(NoShowReport.isConflict({'status': 'success'}), isFalse);
    });
  });

  group('«سبق الإبلاغ» — 422 وهو نجاح متأخّر', () {
    test('رسالة الراكب', () {
      expect(
        NoShowReport.isAlreadyReported(
            'You have already submitted a no-show report for this ride.'),
        isTrue,
      );
    });

    test('رسالة السائق', () {
      expect(
        NoShowReport.isAlreadyReported(
            'You have already submitted a no-show report for this booking.'),
        isTrue,
      );
    });

    test('أخطاء أخرى ليست منها', () {
      for (final message in const [
        'No confirmed booking found for you on this ride.',
        'You can only report no-shows for your own rides.',
        'Cannot report no-show for a ride with status: finished.',
      ]) {
        expect(NoShowReport.isAlreadyReported(message), isFalse);
      }
    });
  });

  group('الدقائق المتبقية تُقرأ من الخادم لا تُحسب محلياً', () {
    test('تُستخرج من رسالة القفل', () {
      expect(
        NoShowReport.minutesUntilUnlock(
            'No-show reporting unlocks 1 hour after departure. 37 minute(s) '
            'remaining.'),
        37,
      );
    });

    test('دقيقة واحدة', () {
      expect(
        NoShowReport.minutesUntilUnlock(
            'No-show reporting unlocks 1 hour after departure. 1 minute(s) '
            'remaining.'),
        1,
      );
    });

    test('رسالة أخرى تُعيد null فلا تُقرأ ساعتها الواحدة كدقائق', () {
      // «1 hour» في نصّ آخر لا يعني دقائق متبقية
      expect(
        NoShowReport.minutesUntilUnlock(
            'No confirmed booking found for you on this ride.'),
        isNull,
      );
    });
  });

  group('الترجمة إلى العربية', () {
    test('رسالة القفل تحمل الدقائق بصيغة العربية', () {
      final text = HandelErorrMessage.driverNoShow(
          'No-show reporting unlocks 1 hour after departure. 37 minute(s) '
          'remaining.');

      expect(text, contains('37 دقيقة'));
      expect(text, isNot(contains('minute')));
    });

    test('الرسالة لا تَعِد بمهلة من عندها', () {
      final text = HandelErorrMessage.driverNoShow(
          'No-show reporting unlocks 1 hour after departure. 37 minute(s) '
          'remaining.');

      expect(text, isNot(contains('بعد ساعة من الانطلاق')),
          reason: 'المهلة مهلة الخادم وقد تتغيّر — الباقي وحده ما يُقال');
      expect(text, contains('37 دقيقة'));
    });

    test('دقيقتان تُثنّى ولا تُرقَّم', () {
      final text = HandelErorrMessage.passengerNoShow(
          'No-show reporting unlocks 1 hour after departure. 2 minute(s) '
          'remaining.');

      expect(text, contains('دقيقتين'));
      expect(text, isNot(contains('2 دقيقة')));
    });

    test('كل رسائل 422 التسع مترجمة — لا إنجليزية تصل المستخدم', () {
      const passengerSide = [
        'No-show reporting unlocks 1 hour after departure. 37 minute(s) remaining.',
        'Cannot report no-show for a ride with status: finished.',
        'No query results for model [App\\Models\\Ride] 12',
        'No confirmed booking found for you on this ride.',
        'You have already submitted a no-show report for this ride.',
      ];
      const driverSide = [
        'No-show reporting unlocks 1 hour after departure. 5 minute(s) remaining.',
        'Cannot report no-show for a ride with status: finished.',
        'No query results for model [App\\Models\\Booking] 3',
        'You can only report no-shows for your own rides.',
        "Booking #14 is not in 'confirmed' status — cannot report no-show.",
        'You have already submitted a no-show report for this booking.',
      ];

      for (final raw in passengerSide) {
        final text = HandelErorrMessage.driverNoShow(raw);
        expect(text, isNot(equals(raw)), reason: 'لم تُترجم: $raw');
        expect(text, isNot(contains('No ')), reason: 'إنجليزية باقية: $raw');
      }
      for (final raw in driverSide) {
        final text = HandelErorrMessage.passengerNoShow(raw);
        expect(text, isNot(equals(raw)), reason: 'لم تُترجم: $raw');
        expect(text, isNot(contains('Booking #')), reason: 'خام: $raw');
      }
    });

    test('رسالة مجهولة تسقط إلى نصّ عام لا إلى الإنجليزية', () {
      final text = HandelErorrMessage.driverNoShow('Something new happened');

      expect(text, isNot(contains('Something')));
    });
  });

  group('بوابة الإبلاغ — متى تُفتح', () {
    final departure = DateTime(2026, 8, 20, 10);

    test('قبل الانطلاق: البوابة مقفلة وما بقي نصف ساعة ودقيقة', () {
      final now = departure.subtract(const Duration(minutes: 30));

      expect(RideTimeRules.canReportNoShow(departure, now: now), isFalse);
      expect(RideTimeRules.untilNoShowGate(departure, now: now),
          const Duration(minutes: 31));
    });

    test('مع الانطلاق: دقيقة واحدة باقية', () {
      expect(RideTimeRules.untilNoShowGate(departure, now: departure),
          const Duration(minutes: 1),
          reason: 'المهلة قُصّرت من ساعة إلى دقيقة (2026-08-20)');
    });

    test('بعد نصف دقيقة: نصفها باقٍ', () {
      final now = departure.add(const Duration(seconds: 30));

      expect(RideTimeRules.canReportNoShow(departure, now: now), isFalse);
      expect(RideTimeRules.untilNoShowGate(departure, now: now),
          const Duration(seconds: 30));
    });

    test('عند الدقيقة تماماً: تُفتح ولا عدّاد', () {
      final now = departure.add(const Duration(minutes: 1));

      expect(RideTimeRules.canReportNoShow(departure, now: now), isTrue);
      expect(RideTimeRules.untilNoShowGate(departure, now: now), isNull);
    });

    test('بعدها: تبقى مفتوحة', () {
      final now = departure.add(const Duration(hours: 5));

      expect(RideTimeRules.canReportNoShow(departure, now: now), isTrue);
      expect(RideTimeRules.untilNoShowGate(departure, now: now), isNull);
    });
  });
}
