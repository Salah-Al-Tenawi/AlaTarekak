import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:alatarekak/features/support/domain/entity/faq_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// كل نصوص الأسئلة الشائعة في سلسلة واحدة للبحث فيها.
String get _allAnswers =>
    FaqData.groups.expand((g) => g.entries).map((e) => e.answer).join(' ');

void main() {
  group('FaqData — سلامة البنية', () {
    test('لا مجموعة فارغة ولا سؤال بلا جواب', () {
      expect(FaqData.groups, isNotEmpty);
      for (final g in FaqData.groups) {
        expect(g.title, isNotEmpty);
        expect(g.entries, isNotEmpty, reason: 'المجموعة "${g.title}" فارغة');
        for (final e in g.entries) {
          expect(e.question, isNotEmpty);
          expect(e.answer, isNotEmpty,
              reason: 'السؤال "${e.question}" بلا جواب');
        }
      }
    });

    test('لا سؤال مكرر', () {
      final questions =
          FaqData.groups.expand((g) => g.entries).map((e) => e.question);
      expect(questions.toSet().length, questions.length);
    });
  });

  group('FaqData — الإجابات تطابق قواعد التطبيق الفعلية', () {
    test('حدّا نقاط الثقة كما يفرضهما الخادم (40 للحجز، 50 للإنشاء)', () {
      final score = FaqData.groups
          .firstWhere((g) => g.title.contains('نقاط الثقة'))
          .entries
          .map((e) => e.answer)
          .join(' ');

      expect(score, contains('50'));
      expect(score, contains('40'));
      expect(score, contains('70')); // النقطة الابتدائية
    });

    test('نسب الاسترداد لا تناقض سياسة الإلغاء', () {
      final faqRefund = FaqData.groups
          .firstWhere((g) => g.title.contains('الإلغاء'))
          .entries
          .map((e) => e.answer)
          .join(' ');

      // النسب الأربع نفسها الواردة في PolicyText.cancellation
      for (final pct in ['30%', '50%', '70%']) {
        expect(faqRefund, contains(pct),
            reason: 'نسبة $pct مذكورة في السياسة وغائبة عن الأسئلة الشائعة');
      }
    });

    test('رسوم الرحلات النقدية 5% كما في السياسة', () {
      expect(_allAnswers, contains('5%'));

      final policyFee = PolicyText.cancellation
          .firstWhere((s) => s.title.contains('رسوم'))
          .intro!;
      expect(policyFee, contains('5%'));
    });

    test('صيغة رقم الهاتف المذكورة تطابق ما يفرضه التطبيق', () {
      expect(_allAnswers, contains('09'));
      expect(_allAnswers, contains('0912345678'));
    });

    test('لا تَعِد بميزات غير موجودة — حذف الحساب يمرّ عبر الدعم', () {
      final deletion = FaqData.groups
          .expand((g) => g.entries)
          .firstWhere((e) => e.question.contains('حذف حسابي'))
          .answer;

      expect(deletion, contains('راسلنا'));
      expect(deletion, contains('90'));
    });
  });
}
