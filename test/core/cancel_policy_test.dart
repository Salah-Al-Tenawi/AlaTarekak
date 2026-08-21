import 'package:alatarekak/core/utils/class/cancel_policy.dart';
import 'package:flutter_test/flutter_test.dart';

/// كلفة الإلغاء — شرائحها وعتباتها كما في سياسة الخادم.
///
/// **`elapsed%` ليست ما بقي على الانطلاق** بل ما انقضى من عمر الحجز:
/// حجزٌ أُنشئ قبل الانطلاق بساعة يبلغ 70% خلال اثنتين وأربعين دقيقة،
/// وحجزٌ أُنشئ قبل أسبوع يحتاج خمسة أيام. وهي مصدر كل عقوبة.
void main() {
  group('نسبة ما انقضى', () {
    final created = DateTime(2026, 8, 20, 10);
    final departure = DateTime(2026, 8, 20, 20); // نافذة عشر ساعات

    double? at(DateTime now) => CancelPolicy.elapsedPercent(
        createdAt: created, departure: departure, now: now);

    test('لحظة الإنشاء: صفر', () {
      expect(at(created), 0);
    });

    test('منتصف النافذة: خمسون', () {
      expect(at(DateTime(2026, 8, 20, 15)), 50);
    });

    test('حجزٌ أُنشئ قبل الانطلاق بساعة يبلغ 70% خلال 42 دقيقة', () {
      final tight = CancelPolicy.elapsedPercent(
        createdAt: DateTime(2026, 8, 20, 10),
        departure: DateTime(2026, 8, 20, 11),
        now: DateTime(2026, 8, 20, 10, 42),
      );

      expect(tight, closeTo(70, 0.1),
          reason: 'المثال الذي ضربه الباك إند بعينه');
    });

    test('بعد الانطلاق: مئة لا أكثر', () {
      expect(at(DateTime(2026, 8, 21)), 100);
    });

    test('بلا وقت إنشاء: لا نعرف — ولا نفترض صفراً', () {
      expect(
        CancelPolicy.elapsedPercent(createdAt: null, departure: departure),
        isNull,
        reason: 'افتراض الصفر يَعِد باسترداد كامل لا يقع',
      );
    });

    test('انطلاقٌ يسبق الإنشاء: بيانات مكسورة، لا نعرف', () {
      expect(
        CancelPolicy.elapsedPercent(
            createdAt: departure, departure: created),
        isNull,
      );
    });
  });

  group('شرائح الاسترداد — أربع', () {
    test('حتى 30%: كامل', () {
      expect(CancelPolicy.refundPercent(0), 100);
      expect(CancelPolicy.refundPercent(30), 100);
    });

    test('30–50%: سبعون', () {
      expect(CancelPolicy.refundPercent(30.1), 70);
      expect(CancelPolicy.refundPercent(50), 70);
    });

    test('50–70%: نصف', () {
      expect(CancelPolicy.refundPercent(50.1), 50);
      expect(CancelPolicy.refundPercent(70), 50);
    });

    test('بعد 70%: لا شيء', () {
      expect(CancelPolicy.refundPercent(70.1), 0);
      expect(CancelPolicy.refundPercent(100), 0);
    });
  });

  group('نقاط الراكب — ثلاث عتبات لا أربع', () {
    int points(double elapsed) =>
        CancelPolicy.passengerCancelPoints(elapsed: elapsed, cashRide: true);

    test('حتى 30%: بلا خصم', () {
      expect(points(30), 0);
    });

    test('30–50%: خمس', () {
      expect(points(40), 5);
    });

    test('**بين 50 و70 يخسر نصف المبلغ وعشر نقاط معاً**', () {
      expect(CancelPolicy.refundPercent(60), 50);
      expect(points(60), 10,
          reason: 'عتبة النقاط الأخيرة 50% لا 70% — والفرق يفاجئ من '
              'يظنّ الجدولين واحداً');
    });

    test('الدفع الإلكتروني لا يخصم نقاطاً في أي شريحة', () {
      for (final elapsed in [0.0, 40.0, 60.0, 90.0, 100.0]) {
        expect(
          CancelPolicy.passengerCancelPoints(
              elapsed: elapsed, cashRide: false),
          0,
          reason: 'خسارة المبلغ هي العقوبة، فلا تُضاعَف — عند $elapsed%',
        );
      }
    });
  });

  group('نقاط السائق ورسوم الإنشاء', () {
    test('حتى 30%: بلا خصم ورسومه تعود', () {
      expect(CancelPolicy.driverCancelRidePoints(30), 0);
      expect(
          CancelPolicy.creationFeeRefunded(elapsed: 30, hasPassengers: true),
          isTrue);
    });

    test('30–50%: سبع نقاط', () {
      expect(CancelPolicy.driverCancelRidePoints(40), 7);
    });

    test('بعد 50%: اثنتا عشرة', () {
      expect(CancelPolicy.driverCancelRidePoints(50.1), 12);
      expect(CancelPolicy.driverCancelRidePoints(100), 12);
    });

    test('الرسوم تُحتجز بتأخّر الإلغاء وفي الرحلة ركّاب', () {
      expect(
          CancelPolicy.creationFeeRefunded(elapsed: 80, hasPassengers: true),
          isFalse);
    });

    test('ورحلةٌ بلا ركّاب تُعاد رسومها مهما تأخّر إلغاؤها', () {
      expect(
          CancelPolicy.creationFeeRefunded(elapsed: 99, hasPassengers: false),
          isTrue);
    });
  });

  group('ما يُقال للراكب', () {
    List<String> texts({
      double? elapsed,
      int amount = 10000,
      bool cash = false,
    }) =>
        CancelPolicy.passengerCancel(
                elapsed: elapsed, amount: amount, cashRide: cash)
            .map((c) => c.text)
            .toList();

    test('الشريحة الأولى: لا تحذير حيث لا كلفة', () {
      final lines = texts(elapsed: 10);

      expect(lines.first, contains('كامل المبلغ'));
      expect(lines.last, contains('لن تخسر'));
      expect(lines.join(), isNot(contains('تُخصم')));
    });

    // **الاسترداد والنقاط لا يجتمعان**: الاسترداد حركة محفظة لا تقع إلا
    // في الدفع الإلكتروني، والنقاط لا تُخصم إلا في النقدي. ومثال الباك
    // إند جمعهما في بطاقة واحدة («70% ومعها −5 نقاط») — وهو خلط عمودَي
    // جدولهما نفسه.
    test('الشريحة الثانية إلكترونياً: المبلغ محسوباً لا نسبةً وحدها', () {
      final lines = texts(elapsed: 40);

      expect(lines.first, contains('70%'));
      expect(lines.first, contains('7,000 ل.س'),
          reason: 'المثال الذي ضربه الباك إند: ٧٠٠٠ من ١٠٠٠٠');
      expect(lines.first, contains('10,000 ل.س'));
      expect(lines.last, contains('لن تخسر'));
    });

    test('والشريحة نفسها نقداً: خمس نقاط بلا وعد باسترداد', () {
      final lines = texts(elapsed: 40, cash: true);

      expect(lines.first, contains('نقديّ'));
      expect(lines.last, contains('5 نقاط'));
    });

    test('بعد 70% نقداً: عشر نقاط', () {
      expect(texts(elapsed: 80, cash: true).last, contains('10 نقاط'));
    });

    test('الإلكتروني: خسارة مال بلا نقاط', () {
      final lines = texts(elapsed: 80);

      expect(lines.first, contains('لا يُعاد شيء'));
      expect(lines.last, contains('لن تخسر'));
    });

    test('النقدي: لا وعد باسترداد أصلاً', () {
      expect(texts(elapsed: 10, cash: true).first, contains('نقديّ'));
    });

    test('بلا نسبة: جملة عامّة بلا رقم مخترع', () {
      final lines = texts(elapsed: null);

      expect(lines, hasLength(1));
      expect(lines.single, contains('يعتمد'));
    });
  });

  group('ما يُقال للسائق', () {
    List<String> texts({double? elapsed, int passengers = 3}) =>
        CancelPolicy.driverCancelRide(
                elapsed: elapsed, passengers: passengers)
            .map((c) => c.text)
            .toList();

    test('الركّاب يُستردّ لهم كامل المبلغ مهما تأخّر الإلغاء', () {
      expect(texts(elapsed: 95).first, contains('كامل المبلغ'));
    });

    test('وعددهم بصيغة العربية', () {
      expect(texts(elapsed: 10, passengers: 2).first, contains('راكبين'));
      expect(texts(elapsed: 10, passengers: 1).first, contains('راكب'));
    });

    test('رحلة بلا حجوزات: لا إشعار ولا استرداد', () {
      expect(texts(elapsed: 95, passengers: 0).first, contains('لا حجوزات'));
    });

    test('الإلغاء المبكر لا يكلّف شيئاً', () {
      final lines = texts(elapsed: 10);

      expect(lines[1], contains('لن تخسر'));
      expect(lines[2], contains('وتُعاد إليك رسوم'));
    });

    test('والمتأخّر يجمع الخصمين', () {
      final lines = texts(elapsed: 90);

      expect(lines[1], contains('12 نقطة'));
      expect(lines[2], contains('لن تُعاد رسوم'));
    });
  });

  group('بلاغ الغياب — لا شيء يقع فوراً', () {
    test('السائق يبلّغ في رحلة إلكترونية: 95% تُحوَّل إليه', () {
      final lines =
          CancelPolicy.noShowReport(againstPassenger: true, cashRide: false)
              .map((c) => c.text)
              .toList();

      expect(lines.first, contains('لا يقع شيء الآن'));
      expect(lines[1], contains('95%'));
      expect(lines.last, contains('تُفتح شكوى'));
    });

    test('وفي النقدية لا يُوعَد بمال لا وجود له', () {
      final lines =
          CancelPolicy.noShowReport(againstPassenger: true, cashRide: true)
              .map((c) => c.text)
              .toList();

      expect(lines.join(), isNot(contains('95%')),
          reason: 'لا مبلغ محتجزاً في النقدي ليُحوَّل');
      expect(lines[1], contains('15 نقطة'));
    });

    test('الراكب يبلّغ: استرداد كامل وخصم خمس عشرة نقطة', () {
      final lines =
          CancelPolicy.noShowReport(againstPassenger: false, cashRide: true)
              .map((c) => c.text)
              .toList();

      expect(lines[1], contains('كامل مبلغك'));
      expect(lines[1], contains('15 نقطة'));
    });

    test('ولا تُذكر مدّة المهلة — ثابتها عند الخادم في وضع تجريب', () {
      for (final against in [true, false]) {
        final joined = CancelPolicy.noShowReport(
                againstPassenger: against, cashRide: false)
            .map((c) => c.text)
            .join();

        expect(joined, contains('مهلة للاعتراض'));
        expect(joined, isNot(contains('ساعتان')));
        expect(joined, isNot(contains('دقيقتين')));
      }
    });
  });
}
