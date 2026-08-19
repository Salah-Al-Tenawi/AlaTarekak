import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_status_filter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures.dart';

/// تصنيف حجوزات «حجوزاتي» إلى مجموعات.
///
/// الشاشة كانت تعرض الحجوزات كلها في قائمة واحدة: الملغى بين المؤكَّد
/// وطلبٌ ينتظر الردّ بين رحلات انتهت. التصنيف يفصلها — وهذه الاختبارات
/// تثبّت أيّ حالة خام تقع في أيّ مجموعة، فحالة جديدة من الخادم لا تسقط
/// صامتة في المجموعة الخطأ.
void main() {
  group('انتماء الحالة إلى مجموعتها', () {
    const cases = {
      'pending': BookingStatusFilter.pending,
      'accepted': BookingStatusFilter.confirmed,
      'confirmed': BookingStatusFilter.confirmed,
      'awaiting_confirmation': BookingStatusFilter.confirmed,
      'ongoing': BookingStatusFilter.confirmed,
      'completed': BookingStatusFilter.completed,
      'finished': BookingStatusFilter.completed,
      'cancelled': BookingStatusFilter.cancelled,
      'canceled': BookingStatusFilter.cancelled,
      'rejected': BookingStatusFilter.cancelled,
      'no_show': BookingStatusFilter.cancelled,
    };

    cases.forEach((status, expected) {
      test('«$status» ← ${expected.label}', () {
        expect(expected.matches(status), isTrue);

        // ولا تقع في غيرها: مجموعتان تدّعيان الحالة نفسها تعني حجزاً
        // يظهر مرّتين لمن يتنقّل بين التبويبات.
        for (final other in BookingStatusFilter.values) {
          if (other == expected || other == BookingStatusFilter.all) continue;
          expect(other.matches(status), isFalse,
              reason: '${other.label} لا يجوز أن تدّعي «$status»');
        }
      });
    });

    test('الحالة تُطبَّع: CONFIRMED ومسافات زائدة', () {
      expect(BookingStatusFilter.confirmed.matches('  CONFIRMED '), isTrue);
    });

    test('«الكل» تقبل كل شيء — حتى ما لا نعرفه', () {
      for (final status in const ['pending', 'zombie', '', 'CANCELLED']) {
        expect(BookingStatusFilter.all.matches(status), isTrue);
      }
    });

    test('حالة مجهولة تبقى في «الكل» وحدها — لا تُحشر بالتخمين', () {
      for (final filter in BookingStatusFilter.values) {
        if (filter == BookingStatusFilter.all) continue;
        expect(filter.matches('teleported'), isFalse);
      }
    });
  });

  group('apply — تصفية قائمة', () {
    final bookings = [
      fakeBooking(bookingId: 1, status: 'pending'),
      fakeBooking(bookingId: 2, status: 'confirmed'),
      fakeBooking(bookingId: 3, status: 'cancelled'),
      fakeBooking(bookingId: 4, status: 'rejected'),
      fakeBooking(bookingId: 5, status: 'completed'),
      fakeBooking(bookingId: 6, status: 'accepted'),
    ];

    test('«ملغاة» تجمع الملغى والمرفوض ولا شيء غيرهما', () {
      final ids = BookingStatusFilter.cancelled
          .apply(bookings)
          .map((b) => b.bookingId)
          .toList();

      expect(ids, [3, 4]);
    });

    test('«مؤكّدة» تجمع confirmed و accepted', () {
      final ids = BookingStatusFilter.confirmed
          .apply(bookings)
          .map((b) => b.bookingId)
          .toList();

      expect(ids, [2, 6]);
    });

    test('«الكل» تُعيد القائمة كما هي بترتيبها', () {
      expect(BookingStatusFilter.all.apply(bookings), same(bookings));
    });

    test('التصفية تحفظ الترتيب الوارد من الخادم', () {
      final reversed = bookings.reversed.toList();
      final ids = BookingStatusFilter.cancelled
          .apply(reversed)
          .map((b) => b.bookingId)
          .toList();

      expect(ids, [4, 3]);
    });
  });

  group('countByFilter', () {
    test('عدّاد كل مجموعة، و«الكل» مجموعها', () {
      final counts = countByFilter([
        fakeBooking(bookingId: 1, status: 'pending'),
        fakeBooking(bookingId: 2, status: 'cancelled'),
        fakeBooking(bookingId: 3, status: 'canceled'),
        fakeBooking(bookingId: 4, status: 'finished'),
      ]);

      expect(counts[BookingStatusFilter.all], 4);
      expect(counts[BookingStatusFilter.pending], 1);
      expect(counts[BookingStatusFilter.confirmed], 0);
      expect(counts[BookingStatusFilter.completed], 1);
      expect(counts[BookingStatusFilter.cancelled], 2);
    });

    test('قائمة فارغة: أصفار لا مفاتيح ناقصة', () {
      final counts = countByFilter([]);

      for (final filter in BookingStatusFilter.values) {
        expect(counts[filter], 0, reason: '${filter.label} يجب أن يكون 0');
      }
    });
  });

  test('لكل مجموعة رسالة فراغ خاصّة بها', () {
    final messages =
        BookingStatusFilter.values.map((f) => f.emptyMessage).toSet();

    expect(messages.length, BookingStatusFilter.values.length,
        reason: 'رسالة واحدة لمجموعتين تُوهم أن الحجوزات كلها اختفت');
    expect(BookingStatusFilter.all.emptyMessage, 'لا توجد حجوزات');
  });
}
