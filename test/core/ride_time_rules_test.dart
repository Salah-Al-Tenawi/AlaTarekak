import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// القواعد الزمنية لإجراءات الرحلة والحجز.
///
/// تغيّرت المتطلبات (2026-08-18): السائق لم يعد يُنهي الرحلة — تكتمل
/// بتأكيد الركّاب. وبقي له الإلغاء وحده — متاحاً حتى لحظة الانطلاق
/// بلا مهلة مسبقة.
///
/// ثم (2026-08-20) قُصّرت مهلة بلاغ عدم الحضور من ساعة إلى **دقيقة**
/// واحدة بعد الموعد.

final DateTime _departure = DateTime(2026, 8, 20, 10, 0);

void main() {
  group('الانطلاق', () {
    test('قبل الموعد بدقيقة: لم تنطلق', () {
      expect(
        RideTimeRules.hasDeparted(_departure,
            now: _departure.subtract(const Duration(minutes: 1))),
        isFalse,
      );
    });

    test('عند الموعد بالضبط: انطلقت', () {
      expect(RideTimeRules.hasDeparted(_departure, now: _departure), isTrue);
    });
  });

  group('الإلغاء متاح حتى لحظة الانطلاق (لا مهلة مسبقة)', () {
    test('قبل الموعد بيوم: مسموح', () {
      expect(
        RideTimeRules.canCancelRide(_departure,
            now: _departure.subtract(const Duration(days: 1))),
        isTrue,
      );
    });

    test('قبله بساعة: مسموح', () {
      expect(
        RideTimeRules.canCancelRide(_departure,
            now: _departure.subtract(const Duration(hours: 1))),
        isTrue,
        reason: 'جُرّبت مهلة ساعة ثم أُلغيت بقرار صريح',
      );
    });

    test('قبله بنصف ساعة: مسموح', () {
      expect(
        RideTimeRules.canCancelRide(_departure,
            now: _departure.subtract(const Duration(minutes: 30))),
        isTrue,
      );
    });

    test('قبله بدقيقة واحدة: مسموح', () {
      expect(
        RideTimeRules.canCancelRide(_departure,
            now: _departure.subtract(const Duration(minutes: 1))),
        isTrue,
        reason: 'ظرف طارئ يقع، ومنع الإلغاء يدفع إلى غياب بلا إخطار',
      );
    });

    test('عند الموعد بالضبط: ممنوع', () {
      expect(
        RideTimeRules.canCancelRide(_departure, now: _departure),
        isFalse,
      );
    });

    test('بعد الانطلاق: ممنوع', () {
      expect(
        RideTimeRules.canCancelRide(_departure,
            now: _departure.add(const Duration(minutes: 5))),
        isFalse,
      );
    });

    test('الإلغاء متاح ما دامت لم تنطلق — القاعدتان متطابقتان', () {
      for (var m = -600; m <= 120; m += 5) {
        final now = _departure.add(Duration(minutes: m));
        expect(
          RideTimeRules.canCancelRide(_departure, now: now),
          !RideTimeRules.hasDeparted(_departure, now: now),
          reason: 'عند الدقيقة $m',
        );
      }
    });
  });

  group('بلاغ عدم الحضور — بعد دقيقة من الانطلاق', () {
    test('المهلة دقيقة واحدة لا ساعة', () {
      expect(RideTimeRules.noShowDelay, const Duration(minutes: 1));
    });

    test('قبل الانطلاق: ممنوع', () {
      expect(
        RideTimeRules.canReportNoShow(_departure,
            now: _departure.subtract(const Duration(minutes: 5))),
        isFalse,
      );
    });

    test('مع الانطلاق مباشرة: ممنوع', () {
      expect(
        RideTimeRules.canReportNoShow(_departure, now: _departure),
        isFalse,
        reason: 'من انطلق للتوّ ليس غائباً',
      );
    });

    test('بعده بنصف دقيقة: ممنوع', () {
      expect(
        RideTimeRules.canReportNoShow(_departure,
            now: _departure.add(const Duration(seconds: 30))),
        isFalse,
        reason: 'المهلة دقيقة كاملة، ونصفها لا يكفي',
      );
    });

    test('عند الدقيقة بالضبط: مسموح', () {
      expect(
        RideTimeRules.canReportNoShow(_departure,
            now: _departure.add(const Duration(minutes: 1))),
        isTrue,
      );
    });

    test('بعد ساعة: مسموح', () {
      expect(
        RideTimeRules.canReportNoShow(_departure,
            now: _departure.add(const Duration(hours: 1))),
        isTrue,
      );
    });
  });

  group('القاعدتان لا تتداخلان', () {
    test('لا لحظة يُسمح فيها بالإلغاء والبلاغ معاً', () {
      for (var m = -180; m <= 180; m += 5) {
        final now = _departure.add(Duration(minutes: m));
        final cancel = RideTimeRules.canCancelRide(_departure, now: now);
        final report = RideTimeRules.canReportNoShow(_departure, now: now);

        expect(cancel && report, isFalse, reason: 'عند الدقيقة $m');
      }
    });
  });
}
