import 'package:alatarekak/features/trip_create/domin/ride_price_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// تسعير الرحلة بالليرة السورية.
///
/// كان المقترح شريحتين: سعرٌ حتى 65 كم وأعلى منه فوقها — والشريحة الأعلى
/// تُطبَّق على المسافة كاملة، فتقفز رحلة 66 كم فوق رحلة 65 كم قفزةً
/// واحدة كبيرة. وكانت الزيادة بلا سقف إطلاقاً.
///
/// **الأسعار تتغيّر — والسلوك لا.** فالتأكيدات هنا مشتقّة من ثوابت
/// [RidePriceRules] لا مكتوبة بأرقامها: خطّيّة العلاقة، ووقوع المقترح بين
/// الحدّين، وتماثل الخطوتين، والانحصار في المدى. تُغيَّر النسب في موضعها
/// فتبقى هذه صحيحة. وما يُثبَّت بالأرقام هو الحساب نفسه لا السياسة.
void main() {
  const suggestedRate = RidePriceRules.suggestedRatePerKm;
  const minRate = RidePriceRules.minRatePerKm;
  const maxRate = RidePriceRules.maxRatePerKm;

  group('السعر المقترح', () {
    test('يُبنى على سعر الكيلومتر المقترح', () {
      for (final km in [10.0, 20.0, 45.0]) {
        final rate = RidePriceRules.suggestedFor(km) / km;
        expect(rate, closeTo(suggestedRate, suggestedRate * 0.12),
            reason: 'عند $km كم');
      }
    });

    test('عشرة كيلومترات: ستّ وخمسون', () {
      // تثبيتٌ صريح للحساب: 5.5×10 = 55، مقرَّبةً إلى خطوتها (2) = 56.
      // لو تغيّرت السياسة يُحدَّث هذا وحده
      expect(RidePriceRules.suggestedFor(10), 56);
    });

    test('يُقرَّب إلى خطوته فيبقى العدّاد على أرقام نظيفة', () {
      for (final km in [3.7, 7.3, 11.9, 26.4, 58.2, 140.0]) {
        final suggested = RidePriceRules.suggestedFor(km);
        final step = RidePriceRules.stepFor(suggested);

        expect(suggested % step, 0, reason: 'عند $km كم');
      }
    });

    test('لا قفزة عند حدّ مسافة — العلاقة خطّية', () {
      // كانت 65 كم تعطي 32000 و66 كم تعطي 46000
      final at65 = RidePriceRules.suggestedFor(65);
      final at66 = RidePriceRules.suggestedFor(66);

      expect(at66 - at65, lessThan(at65 * 0.1),
          reason: 'كيلومتر واحد لا يرفع السعر بأكثر من عُشره');
    });

    test('مسافة صفر لا تُعطي سعراً ولا ترمي', () {
      expect(RidePriceRules.suggestedFor(0), 0);
      expect(RidePriceRules.suggestedFor(-5), 0);
    });
  });

  group('الخطوة تكبر مع السعر', () {
    test('نحو ثلاثة في المئة من السعر', () {
      for (final price in [20, 60, 250, 1200]) {
        final step = RidePriceRules.stepFor(price);

        expect(step, greaterThanOrEqualTo(price * 0.03),
            reason: 'عند $price: الخطوة لا تصغر عن النسبة');
        expect(step, lessThan(price * 0.25),
            reason: 'عند $price: ولا تكبر حتى تصير قفزة');
      }
    });

    test('أرقام مريحة لا كسور', () {
      for (final price in [6, 12, 27, 55, 80, 150, 400]) {
        expect(RidePriceRules.stepFor(price),
            isIn(const [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000]),
            reason: 'عند سعر $price');
      }
    });

    test('لا تصغر كلما كبر السعر', () {
      var previous = 0;
      for (final price in [6, 12, 27, 55, 80, 150, 400, 1200]) {
        final step = RidePriceRules.stepFor(price);
        expect(step, greaterThanOrEqualTo(previous), reason: 'عند $price');
        previous = step;
      }
    });
  });

  group('الحدود المطلقة', () {
    test('السقف والأرضية يُضربان في المسافة', () {
      expect(RidePriceRules.maxFor(10), (maxRate * 10).round());
      expect(RidePriceRules.minFor(10), (minRate * 10).round());
    });

    test('الأرضية دون المقترح والسقف فوقه — وإلا فالمدى مقلوب', () {
      expect(minRate, lessThan(suggestedRate));
      expect(maxRate, greaterThan(suggestedRate));
    });

    test('المقترح يقع بينهما دائماً', () {
      for (final km in [1.0, 4.5, 13.3, 50.0, 120.0, 400.0]) {
        final suggested = RidePriceRules.suggestedFor(km);

        expect(suggested, greaterThanOrEqualTo(RidePriceRules.minFor(km)),
            reason: 'عند $km كم');
        expect(suggested, lessThanOrEqualTo(RidePriceRules.maxFor(km)),
            reason: 'عند $km كم');
      }
    });
  });

  group('مدى العدّاد — ±30٪ حول المقترح', () {
    test('يحيط بالمقترح من طرفيه', () {
      const km = 10.0;
      final range = RidePriceRules.stepperRange(km);
      final suggested = RidePriceRules.suggestedFor(km);

      expect(range.min, lessThan(suggested));
      expect(range.max, greaterThan(suggested));
    });

    test('لا يتجاوز الحدّين المطلقين', () {
      for (final km in [1.0, 4.5, 13.3, 80.0, 300.0]) {
        final range = RidePriceRules.stepperRange(km);

        expect(range.min, greaterThanOrEqualTo(RidePriceRules.minFor(km)));
        expect(range.max, lessThanOrEqualTo(RidePriceRules.maxFor(km)));
      }
    });

    test('سعر مكتوب خارج المدى يوسّعه فلا يتجمّد العدّاد', () {
      const km = 10.0;
      // سعر مرتفع لكنه دون السقف
      final high = RidePriceRules.maxFor(km) - 1;
      final range = RidePriceRules.stepperRange(km, current: high);

      expect(range.max, greaterThanOrEqualTo(high),
          reason: 'زرّا العدّاد معطَّلان بلا سبب مفهوم لولا هذا');
      expect(range.max, lessThanOrEqualTo(RidePriceRules.maxFor(km)));
    });
  });

  group('الزيادة والنقصان', () {
    const km = 10.0;

    test('الزيادة بخطوة واحدة', () {
      final suggested = RidePriceRules.suggestedFor(km);
      final step = RidePriceRules.stepFor(suggested);

      expect(RidePriceRules.nextPrice(km, suggested, increase: true),
          suggested + step);
    });

    test('النقصان بخطوة واحدة', () {
      final suggested = RidePriceRules.suggestedFor(km);
      final step = RidePriceRules.stepFor(suggested);

      expect(RidePriceRules.nextPrice(km, suggested, increase: false),
          suggested - step);
    });

    test('الزيادة تقف عند أعلى المدى', () {
      final range = RidePriceRules.stepperRange(km);

      expect(RidePriceRules.nextPrice(km, range.max, increase: true),
          range.max);
    });

    test('النقصان يقف عند أدنى المدى', () {
      final range = RidePriceRules.stepperRange(km);

      expect(RidePriceRules.nextPrice(km, range.min, increase: false),
          range.min);
    });

    test('الزيادة ثم النقصان يعيدان إلى ما كان — خطوتان متماثلتان', () {
      final start = RidePriceRules.suggestedFor(km);
      final up = RidePriceRules.nextPrice(km, start, increase: true);
      final back = RidePriceRules.nextPrice(km, up, increase: false);

      expect(back, start,
          reason: 'كانت خطوة الزيادة تخالف خطوة النقصان فوق حدٍّ معيّن');
    });

    test('لا يخرج عن الحدّ المطلق مهما ضُغط', () {
      var price = RidePriceRules.suggestedFor(km);
      for (var i = 0; i < 100; i++) {
        price = RidePriceRules.nextPrice(km, price, increase: true);
      }

      expect(price, lessThanOrEqualTo(RidePriceRules.maxFor(km)));
    });
  });

  group('التحقّق من السعر المكتوب يدوياً', () {
    const km = 10.0;

    test('ضمن المدى يمرّ — طرفاه مقبولان', () {
      expect(RidePriceRules.validate(km, RidePriceRules.suggestedFor(km)),
          isNull);
      expect(RidePriceRules.validate(km, RidePriceRules.minFor(km)), isNull);
      expect(RidePriceRules.validate(km, RidePriceRules.maxFor(km)), isNull);
    });

    test('فوق المقترح بكثير يمرّ ما دام دون السقف — نقترح ولا نُجبر', () {
      final justUnderCeiling = RidePriceRules.maxFor(km) - 1;

      expect(RidePriceRules.validate(km, justUnderCeiling), isNull);
    });

    test('فوق السقف يُرفض، والرسالة تقول السقف وسعر الكيلومتر', () {
      final error = RidePriceRules.validate(km, RidePriceRules.maxFor(km) + 1);

      expect(error, isNotNull);
      expect(error, contains('${RidePriceRules.maxFor(km)}'));
      expect(error, contains(RidePriceRules.rateLabel(maxRate)));
    });

    test('تحت الأرضية يُرفض، والرسالة تقول الأرضية', () {
      final error = RidePriceRules.validate(km, RidePriceRules.minFor(km) - 1);

      expect(error, isNotNull);
      expect(error, contains('${RidePriceRules.minFor(km)}'));
    });

    test('الصفر والسالب يُرفضان', () {
      expect(RidePriceRules.validate(km, 0), isNotNull);
      expect(RidePriceRules.validate(km, -100), isNotNull);
      expect(RidePriceRules.validate(km, null), isNotNull);
    });

    test('بلا مسافة لا نمنع — الخادم يحسم', () {
      expect(RidePriceRules.validate(0, 50), isNull);
    });
  });

  group('سعر الكيلومتر المعروض', () {
    test('يُحسب من السعر والمسافة', () {
      expect(RidePriceRules.ratePerKm(10, 55), 5.5);
      expect(RidePriceRules.ratePerKm(4, 20), 5);
    });

    test('المقترح يعطي سعر الكيلومتر المقترح مهما كانت المسافة', () {
      for (final km in [3.0, 7.7, 25.0, 88.0, 210.0]) {
        final rate =
            RidePriceRules.ratePerKm(km, RidePriceRules.suggestedFor(km));

        expect(rate, closeTo(suggestedRate, suggestedRate * 0.12),
            reason: 'عند $km كم');
      }
    });

    test('الكسر لا يُقرَّب إلى صحيح — 5.5 ليست 6', () {
      expect(RidePriceRules.rateLabel(5.5), '5.5');
      expect(RidePriceRules.rateLabel(5.5556), '5.6');
    });

    test('والصحيح يبقى بلا كسر معلّق', () {
      expect(RidePriceRules.rateLabel(8), '8');
      expect(RidePriceRules.rateLabel(maxRate), '8');
    });

    test('لا قسمة على صفر', () {
      expect(RidePriceRules.ratePerKm(0, 50), 0);
    });
  });
}
