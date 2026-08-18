import 'package:alatarekak/features/trip_create/domin/ride_price_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// تسعير الرحلة بالليرة السورية الجديدة.
///
/// كان المقترح 500 ل.س/كم حتى 65 كم و700 فوقها — والشريحة الأعلى تُطبَّق
/// على المسافة كاملة، فتقفز رحلة 66 كم فوق رحلة 65 كم بثلاثة عشر ألفاً
/// دفعةً واحدة. وكانت الزيادة بلا سقف إطلاقاً.
///
/// الآن: 60 ل.س/كم مقترحاً، وسقف صلب 100، وأرضية 30.

void main() {
  group('السعر المقترح', () {
    test('ستّون ليرة لكل كيلومتر', () {
      expect(RidePriceRules.suggestedFor(10), 600);
      expect(RidePriceRules.suggestedFor(20), 1200);
    });

    test('رحلة 4.5 كم → 270', () {
      expect(RidePriceRules.suggestedFor(4.5), 270);
    });

    test('رحلة 13.33 كم → 800', () {
      expect(RidePriceRules.suggestedFor(13.333), 800);
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
    test('عشرة عند 270، وخمسة وعشرون عند 800 — وهو المتّفق عليه', () {
      expect(RidePriceRules.stepFor(270), 10);
      expect(RidePriceRules.stepFor(800), 25);
    });

    test('أرقام مريحة لا كسور', () {
      for (final price in [60, 120, 270, 500, 800, 1500, 4000, 12000]) {
        expect(RidePriceRules.stepFor(price),
            isIn(const [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500, 5000]),
            reason: 'عند سعر $price');
      }
    });

    test('لا تصغر كلما كبر السعر', () {
      var previous = 0;
      for (final price in [60, 120, 270, 500, 800, 1500, 4000, 12000, 40000]) {
        final step = RidePriceRules.stepFor(price);
        expect(step, greaterThanOrEqualTo(previous), reason: 'عند $price');
        previous = step;
      }
    });
  });

  group('الحدود المطلقة', () {
    test('السقف مئة ليرة للكيلومتر', () {
      expect(RidePriceRules.maxFor(10), 1000);
      expect(RidePriceRules.maxFor(4.5), 450);
    });

    test('الأرضية ثلاثون — نصف المقترح', () {
      expect(RidePriceRules.minFor(10), 300);
      expect(RidePriceRules.minFor(4.5), 135);
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
    test('رحلة 4.5 كم: من 189 إلى 351', () {
      final range = RidePriceRules.stepperRange(4.5);

      expect(range.min, 189);
      expect(range.max, 351);
    });

    test('لا يتجاوز الحدّين المطلقين', () {
      for (final km in [1.0, 4.5, 13.3, 80.0, 300.0]) {
        final range = RidePriceRules.stepperRange(km);

        expect(range.min, greaterThanOrEqualTo(RidePriceRules.minFor(km)));
        expect(range.max, lessThanOrEqualTo(RidePriceRules.maxFor(km)));
      }
    });

    test('سعر مكتوب خارج المدى يوسّعه فلا يتجمّد العدّاد', () {
      // كتب السائق 420 لرحلة 4.5 كم (مقبول: السقف 450)
      final range = RidePriceRules.stepperRange(4.5, current: 420);

      expect(range.max, greaterThanOrEqualTo(420),
          reason: 'زرّا العدّاد معطَّلان بلا سبب مفهوم لولا هذا');
      expect(range.max, lessThanOrEqualTo(RidePriceRules.maxFor(4.5)));
    });
  });

  group('الزيادة والنقصان', () {
    const km = 4.5; // مقترح 270، خطوة 10، مدى 189–351

    test('الزيادة بخطوة واحدة', () {
      expect(RidePriceRules.nextPrice(km, 270, increase: true), 280);
    });

    test('النقصان بخطوة واحدة', () {
      expect(RidePriceRules.nextPrice(km, 270, increase: false), 260);
    });

    test('الزيادة تقف عند أعلى المدى', () {
      expect(RidePriceRules.nextPrice(km, 350, increase: true), 351);
      expect(RidePriceRules.nextPrice(km, 351, increase: true), 351);
    });

    test('النقصان يقف عند أدنى المدى', () {
      expect(RidePriceRules.nextPrice(km, 190, increase: false), 189);
      expect(RidePriceRules.nextPrice(km, 189, increase: false), 189);
    });

    test('الزيادة ثم النقصان يعيدان إلى ما كان — خطوتان متماثلتان', () {
      const start = 270;
      final up = RidePriceRules.nextPrice(km, start, increase: true);
      final back = RidePriceRules.nextPrice(km, up, increase: false);

      expect(back, start,
          reason: 'كانت الزيادة 5000 والنقصان 10000 فوق الأربعين ألفاً');
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
    const km = 10.0; // مقترح 600، أرضية 300، سقف 1000

    test('ضمن المدى يمرّ', () {
      expect(RidePriceRules.validate(km, 600), isNull);
      expect(RidePriceRules.validate(km, 300), isNull);
      expect(RidePriceRules.validate(km, 1000), isNull);
      expect(RidePriceRules.validate(km, 950), isNull,
          reason: 'أعلى من المقترح بكثير — لكنه دون السقف، ونحن نقترح لا نُجبر');
    });

    test('فوق السقف يُرفض بسببه', () {
      final error = RidePriceRules.validate(km, 1200);

      expect(error, isNotNull);
      expect(error, contains('1000'));
      expect(error, contains('100'));
    });

    test('تحت الأرضية يُرفض بسببه', () {
      final error = RidePriceRules.validate(km, 200);

      expect(error, isNotNull);
      expect(error, contains('300'));
    });

    test('الصفر والسالب يُرفضان', () {
      expect(RidePriceRules.validate(km, 0), isNotNull);
      expect(RidePriceRules.validate(km, -100), isNotNull);
      expect(RidePriceRules.validate(km, null), isNotNull);
    });

    test('بلا مسافة لا نمنع — الخادم يحسم', () {
      expect(RidePriceRules.validate(0, 5000), isNull);
    });
  });

  group('سعر الكيلومتر المعروض', () {
    test('يُحسب من السعر والمسافة', () {
      expect(RidePriceRules.ratePerKm(10, 600), 60);
      expect(RidePriceRules.ratePerKm(4.5, 270), 60);
    });

    test('المقترح يعطي ستّين تقريباً مهما كانت المسافة', () {
      for (final km in [3.0, 7.7, 25.0, 88.0, 210.0]) {
        final rate =
            RidePriceRules.ratePerKm(km, RidePriceRules.suggestedFor(km));

        expect(rate, closeTo(60, 6), reason: 'عند $km كم');
      }
    });

    test('لا قسمة على صفر', () {
      expect(RidePriceRules.ratePerKm(0, 500), 0);
    });
  });
}
