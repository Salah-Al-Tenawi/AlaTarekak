import 'package:alatarekak/core/utils/class/syrian_phone.dart';
import 'package:alatarekak/core/utils/functions/input_valid.dart';
import 'package:flutter_test/flutter_test.dart';

/// الخادم يفرض `^09\d{8}$` ويرفض ما عداه بـ 422 — بما فيه صيغة المفتاح
/// الدولي التي يكتبها كثير من المستخدمين. فالقبول واسع والإرسال ضيّق.
void main() {
  group('SyrianPhone — الصيغ المقبولة تُطبَّع إلى صيغة الخادم', () {
    const expected = '0988626577';

    for (final input in const [
      '0988626577',
      '+963988626577',
      '00963988626577',
      '963988626577',
      '988626577',
      '  0988626577  ',
      '098 862 6577',
      '098-862-6577',
      '+963 988 626 577',
    ]) {
      test('«$input» تُطبَّع إلى $expected', () {
        expect(SyrianPhone.normalize(input), expected);
        expect(SyrianPhone.isValid(input), isTrue);
      });
    }
  });

  group('SyrianPhone — ما يجب رفضه', () {
    for (final input in const [
      '',
      '   ',
      '0888626577', // شبكة غير محمولة: لا تبدأ بـ 09
      '098862657', // ناقص رقماً
      '09886265770', // زائد رقماً
      '+9639886265771', // مفتاح دولي بطول خاطئ
      '+201098862657', // مفتاح دولة أخرى
      'abcdefghij',
      '09abcdefgh',
    ]) {
      test('«$input» مرفوضة', () {
        expect(SyrianPhone.normalize(input), isNull);
        expect(SyrianPhone.isValid(input), isFalse);
      });
    }

    test('null مرفوضة بلا انهيار', () {
      expect(SyrianPhone.normalize(null), isNull);
      expect(SyrianPhone.isValid(null), isFalse);
    });
  });

  test('المطبَّع يطابق ما يقبله الخادم حرفياً', () {
    final normalized = SyrianPhone.normalize('+963988626577')!;
    expect(RegExp(r'^09\d{8}$').hasMatch(normalized), isTrue);
  });

  group('مدقّق الحقول المشترك يقبل الصيغتين', () {
    test('الصيغة المحلية تمرّ', () {
      expect(inputvaild('0988626577', 'nubmerphone', 10, 10), isNull);
    });

    test('صيغة المفتاح الدولي تمرّ — كانت تُرفض رغم صحّتها', () {
      expect(inputvaild('+963988626577', 'nubmerphone', 10, 10), isNull);
    });

    test('رقم غير سوري يُرفض برسالة تذكر الصيغتين', () {
      final error = inputvaild('0888626577', 'nubmerphone', 10, 10);
      expect(error, SyrianPhone.error);
      expect(error, contains('0988626577'));
      expect(error, contains('+963988626577'));
    });

    test('الحقل الفارغ يُرفض قبل فحص الصيغة', () {
      expect(inputvaild('', 'nubmerphone', 10, 10), 'لا يمكن ترك الحقل فارغ');
    });
  });
}
