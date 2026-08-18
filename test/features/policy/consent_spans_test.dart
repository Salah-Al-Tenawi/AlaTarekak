import 'package:alatarekak/features/auth/presentation/view/widget/policy_consent_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// سطر الموافقة في شاشة إنشاء الحساب.
///
/// صار نصّه يُكتب من لوحة الأدمن، وهو نصّ عادي بلا روابط. والموافقة بلا
/// سبيل لقراءة ما يُوافَق عليه لا تصحّ — فيُبحث في النصّ عن عنواني
/// الوثيقتين ويصيران رابطين، ويُلحقان في آخره إن صاغه الأدمن بكلمات أخرى.

final _linkStyle = TextStyle(decoration: TextDecoration.underline);

/// نصوص الأجزاء التي لها نمط رابط، مقرونةً بتبويبها.
List<String> _linkTexts(List<InlineSpan> spans) => spans
    .whereType<TextSpan>()
    .where((s) => s.style == _linkStyle)
    .map((s) => s.text ?? '')
    .toList();

String _plainText(List<InlineSpan> spans) => spans
    .whereType<TextSpan>()
    .map((s) => s.text ?? '')
    .join();

List<InlineSpan> _build(String label, {List<int>? tapped}) => buildConsentSpans(
      label: label,
      linkStyle: _linkStyle,
      recognizerFor: (tab) {
        tapped?.add(tab);
        return null;
      },
    );

void main() {
  group('السطر الافتراضي من الأدمن', () {
    const label = 'أوافق على سياسة الخصوصية وسياسة الإلغاء';

    test('العنوانان يصيران رابطين', () {
      expect(_linkTexts(_build(label)), ['سياسة الخصوصية', 'سياسة الإلغاء']);
    });

    test('النصّ يبقى كما كتبه الأدمن حرفاً بحرف', () {
      expect(_plainText(_build(label)), label);
    });

    test('كل رابط يفتح تبويبه', () {
      final tabs = <int>[];
      _build(label, tapped: tabs);
      expect(tabs, [0, 1]);
    });
  });

  group('صياغات أخرى', () {
    test('الترتيب معكوس: الروابط تتبع مواضعها في النصّ', () {
      const label = 'قرأت سياسة الإلغاء وسياسة الخصوصية وأوافق عليهما';
      final spans = _build(label);

      expect(_linkTexts(spans), ['سياسة الإلغاء', 'سياسة الخصوصية']);
      expect(_plainText(spans), label);
    });

    test('عنوان واحد فقط: الآخر لا يُخترع', () {
      const label = 'أوافق على سياسة الخصوصية';
      expect(_linkTexts(_build(label)), ['سياسة الخصوصية']);
      expect(_plainText(_build(label)), label);
    });

    test('بلا أي عنوان: الرابطان يُلحقان فلا يضيع سبيل القراءة', () {
      const label = 'أوافق على شروط الاستخدام';
      final spans = _build(label);

      expect(_linkTexts(spans), ['سياسة الخصوصية', 'سياسة الإلغاء']);
      expect(_plainText(spans), contains(label));
    });

    test('سطر فارغ لا ينهار', () {
      final spans = _build('');
      expect(_linkTexts(spans), hasLength(2));
    });
  });
}
