import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_time_text.dart';
import 'package:flutter_test/flutter_test.dart';

/// نصّ العدّ التنازلي إلى الانطلاق.
///
/// كان مدفوناً في بطاقة «حجوزاتي» فلم يكن يُختبر، وفيه صيغ العربية
/// الأربع: مفرد ومثنّى وجمع قلّة وجمع كثرة. صار دالّة نقيّة تأخذ [now]
/// فتُختبر بلا انتظار ولا ساعة نظام.
void main() {
  final now = DateTime(2026, 8, 19, 10, 0);

  String? remaining(Duration after) =>
      remainingUntilDeparture(now.add(after), now: now);

  group('الموعد لم يحن', () {
    test('ساعة واحدة — مفرد بلا رقم', () {
      expect(remaining(const Duration(hours: 1)), 'ساعة');
    });

    test('ساعتان — مثنّى بلا رقم', () {
      expect(remaining(const Duration(hours: 2)), 'ساعتين');
    });

    test('خمس ساعات — جمع قلّة مع الرقم', () {
      expect(remaining(const Duration(hours: 5)), '5 ساعات');
    });

    test('خمس عشرة ساعة — جمع كثرة بالمفرد', () {
      expect(remaining(const Duration(hours: 15)), '15 ساعة');
    });

    test('يوم وثلاث ساعات — الوحدتان بواو العطف', () {
      expect(remaining(const Duration(days: 1, hours: 3)), 'يوم و 3 ساعات');
    });

    test('يومان — مثنّى', () {
      expect(remaining(const Duration(days: 2)), 'يومين');
    });

    test('دقائق وحدها حين لا ساعة ولا يوم', () {
      expect(remaining(const Duration(minutes: 20)), '20 دقيقة');
      expect(remaining(const Duration(minutes: 2)), 'دقيقتين');
    });

    test('الدقائق تُحذف مع الأيام — ضجيج في عدّاد بأيام', () {
      final text = remaining(const Duration(days: 3, hours: 2, minutes: 40));

      expect(text, '3 أيام و ساعتين');
      expect(text, isNot(contains('دقيقة')));
    });

    test('الدقائق تبقى مع الساعات وحدها', () {
      expect(remaining(const Duration(hours: 2, minutes: 30)),
          'ساعتين و 30 دقيقة');
    });
  });

  group('الموعد حلّ أو مضى', () {
    test('مضى — لا نصّ متبقٍّ', () {
      expect(remaining(const Duration(hours: -1)), isNull);
    });

    test('اللحظة نفسها تُعدّ انطلاقاً لا «صفر دقيقة»', () {
      expect(remainingUntilDeparture(now, now: now), isNull);
    });

    test('الجملة الكاملة تقول إن الرحلة انطلقت', () {
      expect(
        countdownToDeparture(now.subtract(const Duration(minutes: 5)),
            now: now),
        'انطلقت الرحلة',
      );
    });
  });

  test('الجملة الكاملة تسبق المتبقّي بعبارتها', () {
    expect(
      countdownToDeparture(now.add(const Duration(hours: 4)), now: now),
      'باقٍ على الانطلاق: 4 ساعات',
    );
  });
}
