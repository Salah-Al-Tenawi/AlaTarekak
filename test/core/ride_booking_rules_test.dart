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

  group('انتهاء الرحلة — isRideOver', () {
    test('المنتهية والمكتملة والملغاة: انتهت', () {
      expect(isRideOver('finished'), isTrue);
      expect(isRideOver('completed'), isTrue);
      expect(isRideOver('cancelled'), isTrue);
      expect(isRideOver('canceled'), isTrue);
    });

    test('القائمة والممتلئة: لم تنتهِ', () {
      expect(isRideOver('active'), isFalse);
      expect(isRideOver('full'), isFalse,
          reason: 'الامتلاء حالة رحلة قائمة لم تنطلق بعد');
    });

    test('حالة مجهولة أو فارغة لا تُعدّ انتهاءً', () {
      expect(isRideOver(''), isFalse);
      expect(isRideOver('something_new'), isFalse,
          reason: 'الإخفاء بالتخمين يحرم السائق من إجراء يحتاجه');
    });

    test('المطابقة تُطبّع الأحرف والفراغات', () {
      expect(isRideOver('  FINISHED '), isTrue);
    });
  });

  group('رحلة انطلقت بإعلان السائق — لا بمرور الموعد', () {
    // `launched` اسمها الجديد، و`awaiting_confirmation` القديم. وسائق
    // يُعلن انطلاقه قبل موعده يجعل الحالة تسبق الساعة.
    final soon = DateTime.now().add(const Duration(hours: 2));

    test('launched قبل الموعد: لا تُحجز', () {
      expect(bookingBlockFor(status: 'launched', departure: soon),
          BookingBlock.departed,
          reason: 'كان يُعرض «احجز» على رحلة يردّ الخادم حجزها');
    });

    test('awaiting_confirmation كذلك — الاسم القديم', () {
      expect(
          bookingBlockFor(status: 'awaiting_confirmation', departure: soon),
          BookingBlock.departed);
    });

    test('والمتاحة قبل موعدها تبقى تُحجز', () {
      expect(bookingBlockFor(status: 'active', departure: soon), isNull);
    });

    test('انطلاقها ليس انتهاءً: البلاغ عن الغياب يبقى متاحاً', () {
      expect(isRideOver('launched'), isFalse);
      expect(isRideOver('awaiting_confirmation'), isFalse,
          reason: 'الغياب يقع في هذه الحالة بعينها — إخفاء البلاغ فيها '
              'يلغي الميزة');
    });
  });
}
