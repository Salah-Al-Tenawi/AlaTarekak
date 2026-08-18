import 'package:alatarekak/core/utils/class/syria_geo.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

/// حصر نقاط الرحلة داخل سوريا، وتثبيت اتجاه الخرائط.
///
/// المستطيل **كريم عن قصد**: لا يرفض نقطة سورية أبداً — القامشلي وأبو
/// كمال وقنيطرة والبوكمال على الأطراف وهي داخل البلد — ويكتفي بمنع ما
/// هو بعيد بيّن. راجع شرح [SyriaGeo].

void main() {
  group('مدن سورية: كلها مقبولة', () {
    const cities = {
      'دمشق': LatLng(33.5138, 36.2765),
      'حلب': LatLng(36.2021, 37.1343),
      'حمص': LatLng(34.7324, 36.7137),
      'حماة': LatLng(35.1318, 36.7578),
      'اللاذقية': LatLng(35.5196, 35.7915),
      'طرطوس': LatLng(34.8890, 35.8866),
      'دير الزور': LatLng(35.3359, 40.1408),
      'الحسكة': LatLng(36.5024, 40.7477),
      'القامشلي': LatLng(37.0522, 41.2317),
      'الرقة': LatLng(35.9594, 39.0136),
      'السويداء': LatLng(32.7094, 36.5694),
      'درعا': LatLng(32.6189, 36.1021),
      'القنيطرة': LatLng(33.1256, 35.8239),
      'إدلب': LatLng(35.9306, 36.6339),
      'تدمر': LatLng(34.5561, 38.2841),
      'أبو كمال': LatLng(34.4506, 40.9181),
      'الزبداني': LatLng(33.7247, 36.1000),
    };

    for (final entry in cities.entries) {
      test('${entry.key} داخل الحدود', () {
        expect(SyriaGeo.contains(entry.value), isTrue,
            reason: 'رفض مدينة سورية عيب أخطر من قبول نقطة على الحدود');
      });
    }
  });

  group('خارج سوريا: مرفوضة', () {
    const outside = {
      'بيروت': LatLng(33.8938, 35.5018),
      'عمّان': LatLng(31.9539, 35.9106),
      'بغداد': LatLng(33.3152, 44.3661),
      'أنقرة': LatLng(39.9334, 32.8597),
      'إسطنبول': LatLng(41.0082, 28.9784),
      'القاهرة': LatLng(30.0444, 31.2357),
      'الرياض': LatLng(24.7136, 46.6753),
      'قبرص': LatLng(35.1264, 33.4299),
      'وسط البحر المتوسط': LatLng(34.5000, 33.0000),
    };

    for (final entry in outside.entries) {
      test('${entry.key} خارج الحدود', () {
        expect(SyriaGeo.contains(entry.value), isFalse);
      });
    }
  });

  group('الحدود نفسها', () {
    test('الزاوية الجنوبية الغربية مقبولة', () {
      expect(
        SyriaGeo.contains(const LatLng(SyriaGeo.minLat, SyriaGeo.minLng)),
        isTrue,
      );
    });

    test('الزاوية الشمالية الشرقية مقبولة', () {
      expect(
        SyriaGeo.contains(const LatLng(SyriaGeo.maxLat, SyriaGeo.maxLng)),
        isTrue,
      );
    });

    test('ما دون الحدّ الجنوبي مرفوض', () {
      expect(
        SyriaGeo.contains(const LatLng(SyriaGeo.minLat - 0.01, 37.0)),
        isFalse,
      );
    });

    test('ما بعد الحدّ الشرقي مرفوض', () {
      expect(
        SyriaGeo.contains(const LatLng(35.0, SyriaGeo.maxLng + 0.01)),
        isFalse,
      );
    });
  });

  group('حدود الكاميرا', () {
    test('تحيط بالبلد كلها', () {
      expect(SyriaGeo.bounds.contains(const LatLng(33.5138, 36.2765)), isTrue);
      expect(SyriaGeo.bounds.contains(const LatLng(37.0522, 41.2317)), isTrue);
      expect(SyriaGeo.bounds.contains(const LatLng(31.9539, 35.9106)), isFalse);
    });

    test('المركز الافتراضي داخلها', () {
      expect(SyriaGeo.contains(SyriaGeo.center), isTrue);
    });
  });

  group('اتجاه الخريطة مثبَّت', () {
    test('الدوران معطَّل والباقي مسموح', () {
      final flags = kMapInteraction.flags;

      expect(InteractiveFlag.hasFlag(flags, InteractiveFlag.rotate), isFalse,
          reason: 'إصبعان للتقريب يدوران الخريطة بأدنى فرق زاوية');
      expect(InteractiveFlag.hasFlag(flags, InteractiveFlag.pinchZoom), isTrue);
      expect(InteractiveFlag.hasFlag(flags, InteractiveFlag.drag), isTrue);
      expect(
          InteractiveFlag.hasFlag(flags, InteractiveFlag.doubleTapZoom), isTrue);
    });
  });
}
