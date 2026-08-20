import 'package:alatarekak/core/utils/class/ride_booking_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// متى تُحجز الرحلة.
///
/// **الخادم لا يحرس هذا**: أخطاء `POST /rides/{id}/book` في المواصفة
/// تغطّي التوثيق ونقاط الثقة وحجز السائق رحلته وتكرار الحجز وعدد المقاعد
/// والرقم والرصيد — ولا شيء عن موعد الانطلاق ولا عن حالة الرحلة. وقد
/// جُرّب فعلاً: رحلة مضى موعدها قَبِلت الحجز.
void main() {
  final now = DateTime(2026, 8, 20, 12);
  final future = now.add(const Duration(hours: 3));
  final past = now.subtract(const Duration(hours: 3));

  BookingBlock? blockFor(String status, DateTime departure) =>
      bookingBlockFor(status: status, departure: departure, now: now);

  group('الرحلة القادمة تُحجز', () {
    test('نشطة وموعدها لم يحن: لا مانع', () {
      expect(blockFor('active', future), isNull);
    });

    test('ولو بدقيقة واحدة قبل الانطلاق', () {
      expect(
        bookingBlockFor(
          status: 'active',
          departure: now.add(const Duration(minutes: 1)),
          now: now,
        ),
        isNull,
      );
    });

    test('وحالة لا نعرفها لا تمنع — الخادم هو المرجع فيما يعرفه', () {
      expect(blockFor('teleporting', future), isNull);
    });
  });

  group('**الرحلة التي انطلقت لا تُحجز** — العطل المُبلَّغ عنه', () {
    test('مضى موعدها بثلاث ساعات', () {
      expect(blockFor('active', past), BookingBlock.departed);
    });

    test('ولحظة الانطلاق نفسها انطلاق', () {
      expect(blockFor('active', now), BookingBlock.departed);
    });

    test('وبعده بدقيقة', () {
      expect(
        bookingBlockFor(
          status: 'active',
          departure: now.subtract(const Duration(minutes: 1)),
          now: now,
        ),
        BookingBlock.departed,
      );
    });

    test('حتى لو كانت حالتها نشطة عند الخادم', () {
      // الخادم لا يغيّر الحالة بمجرّد حلول الموعد
      expect(blockFor('active', past), BookingBlock.departed);
    });
  });

  group('والرحلة الملغاة أو المنتهية كذلك', () {
    test('ملغاة — ولو كان موعدها غداً', () {
      expect(blockFor('cancelled', future), BookingBlock.cancelled);
      expect(blockFor('canceled', future), BookingBlock.cancelled);
    });

    test('لم يحضر أحد', () {
      expect(blockFor('no_show', future), BookingBlock.cancelled);
    });

    test('منتهية أو مكتملة', () {
      expect(blockFor('finished', past), BookingBlock.finished);
      expect(blockFor('completed', past), BookingBlock.finished);
    });

    test('الحالة تُطبَّع: أحرف كبيرة ومسافات', () {
      expect(blockFor('  CANCELLED ', future), BookingBlock.cancelled);
    });
  });

  group('الأسبقية — أنفع سببٍ يُقال', () {
    test('الملغاة قبل المنطلقة: «ألغيت» أنفع من «انطلقت»', () {
      expect(blockFor('cancelled', past), BookingBlock.cancelled);
    });

    test('المنطلقة قبل الممتلئة: لا معنى لـ«ممتلئة» على رحلة مضت', () {
      expect(blockFor('full', past), BookingBlock.departed);
    });

    test('والممتلئة تبقى سببها حين يكون موعدها قادماً', () {
      expect(blockFor('full', future), BookingBlock.full);
    });
  });

  group('نصوص المنع', () {
    test('لكل سبب تسمية وعنوان وشرح', () {
      for (final block in BookingBlock.values) {
        expect(block.label, isNotEmpty);
        expect(block.title, isNotEmpty);
        expect(block.message, isNotEmpty);
      }
    });

    test('ولا نصّ يَعِد بحجز لا يقع', () {
      for (final block in BookingBlock.values) {
        expect(block.label, isNot(contains('احجز')));
      }
    });

    test('والشرح يقترح ما يفعله المستخدم بعده', () {
      for (final block in BookingBlock.values) {
        expect(block.message, contains('المسار نفسه'),
            reason: '${block.name}: رفضٌ بلا بديل يوقف المستخدم');
      }
    });

    test('نصوص متمايزة — لا سببان بالكلام نفسه', () {
      final labels = BookingBlock.values.map((b) => b.label).toSet();
      expect(labels.length, BookingBlock.values.length);
    });
  });
}
