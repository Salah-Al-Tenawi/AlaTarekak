import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_status_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

/// تصنيف رحلات «رحلاتي» إلى مجموعات.
///
/// كانت الشاشة تعرض الرحلات كلها في قائمة واحدة: رحلة أُلغيت أمس بين
/// رحلتين تنطلقان غداً. التصنيف يفصلها — وهذه الاختبارات تثبّت أيّ حالة
/// خام تقع في أيّ مجموعة، فحالة جديدة من الخادم لا تسقط صامتة في
/// المجموعة الخطأ.
void main() {
  group('انتماء الحالة إلى مجموعتها', () {
    const cases = {
      'active': TripStatusFilter.open,
      'full': TripStatusFilter.full,
      'finished': TripStatusFilter.done,
      'completed': TripStatusFilter.done,
      // `launched` حلّت محلّ `awaiting_confirmation` عند الخادم، وكانت
      // ناقصة هنا: رحلة انطلقت لا تُطابق مجموعةً فتغيب عن كل الرقاقات
      // إلا «الكل»، ويبحث عنها سائقها في «منتهية» فلا يجدها.
      'launched': TripStatusFilter.done,
      'awaiting_confirmation': TripStatusFilter.done,
      'cancelled': TripStatusFilter.cancelled,
      'canceled': TripStatusFilter.cancelled,
      'no_show': TripStatusFilter.cancelled,
    };

    cases.forEach((status, expected) {
      test('«$status» ← ${expected.label}', () {
        expect(expected.matches(status), isTrue);

        // ولا تقع في غيرها: مجموعتان تدّعيان الحالة نفسها تعني رحلة
        // تظهر مرّتين لمن يتنقّل بين التبويبات.
        for (final other in TripStatusFilter.values) {
          if (other == expected || other == TripStatusFilter.all) continue;
          expect(other.matches(status), isFalse,
              reason: '${other.label} لا يجوز أن تدّعي «$status»');
        }
      });
    });

    test('«متاحة» و«ممتلئة» مجموعتان لا واحدة', () {
      // السؤال الأول للسائق: أيّ رحلاتي ما زالت تحتاج ركّاباً؟
      expect(TripStatusFilter.open.matches('full'), isFalse);
      expect(TripStatusFilter.full.matches('active'), isFalse);
    });

    test('الحالة تُطبَّع: ACTIVE ومسافات زائدة', () {
      expect(TripStatusFilter.open.matches('  ACTIVE '), isTrue);
    });

    test('«الكل» تقبل كل شيء — حتى ما لا نعرفه', () {
      for (final status in const ['active', 'teleported', '', 'FULL']) {
        expect(TripStatusFilter.all.matches(status), isTrue);
      }
    });

    test('حالة مجهولة تبقى في «الكل» وحدها — لا تُحشر بالتخمين', () {
      for (final filter in TripStatusFilter.values) {
        if (filter == TripStatusFilter.all) continue;
        expect(filter.matches('draft'), isFalse);
      }
    });
  });

  group('apply — تصفية قائمة', () {
    final trips = [
      fakeTrip(id: 1, status: 'active'),
      fakeTrip(id: 2, status: 'full'),
      fakeTrip(id: 3, status: 'cancelled'),
      fakeTrip(id: 4, status: 'finished'),
      fakeTrip(id: 5, status: 'no_show'),
      fakeTrip(id: 6, status: 'completed'),
    ];

    test('«ملغاة» تجمع الملغى وعدم الحضور ولا شيء غيرهما', () {
      final ids =
          TripStatusFilter.cancelled.apply(trips).map((t) => t.id).toList();

      expect(ids, [3, 5]);
    });

    test('«منتهية» تجمع finished و completed', () {
      final ids =
          TripStatusFilter.done.apply(trips).map((t) => t.id).toList();

      expect(ids, [4, 6]);
    });

    test('«متاحة» لا تشمل الممتلئة', () {
      final ids =
          TripStatusFilter.open.apply(trips).map((t) => t.id).toList();

      expect(ids, [1]);
    });

    test('«الكل» تُعيد القائمة كما هي بترتيبها', () {
      expect(TripStatusFilter.all.apply(trips), same(trips));
    });

    test('التصفية تحفظ الترتيب الوارد من الخادم', () {
      final reversed = trips.reversed.toList();
      final ids =
          TripStatusFilter.cancelled.apply(reversed).map((t) => t.id).toList();

      expect(ids, [5, 3]);
    });
  });

  group('countTripsByFilter', () {
    test('عدّاد كل مجموعة، و«الكل» مجموعها', () {
      final counts = countTripsByFilter([
        fakeTrip(id: 1, status: 'active'),
        fakeTrip(id: 2, status: 'active'),
        fakeTrip(id: 3, status: 'full'),
        fakeTrip(id: 4, status: 'cancelled'),
      ]);

      expect(counts[TripStatusFilter.all], 4);
      expect(counts[TripStatusFilter.open], 2);
      expect(counts[TripStatusFilter.full], 1);
      expect(counts[TripStatusFilter.done], 0);
      expect(counts[TripStatusFilter.cancelled], 1);
    });

    test('قائمة فارغة: أصفار لا مفاتيح ناقصة', () {
      final counts = countTripsByFilter([]);

      for (final filter in TripStatusFilter.values) {
        expect(counts[filter], 0, reason: '${filter.label} يجب أن يكون 0');
      }
    });
  });

  test('لكل مجموعة رسالة فراغ خاصّة بها', () {
    final messages = TripStatusFilter.values.map((f) => f.emptyMessage).toSet();

    expect(messages.length, TripStatusFilter.values.length,
        reason: 'رسالة واحدة لمجموعتين تُوهم أن الرحلات كلها اختفت');
    expect(TripStatusFilter.all.emptyMessage, 'لا توجد رحلات');
  });

  test('ألوان المجموعات متمايزة — لا رقاقتان بلون واحد', () {
    final colors = TripStatusFilter.values.map((f) => f.color).toSet();

    expect(colors.length, TripStatusFilter.values.length);
  });
}
