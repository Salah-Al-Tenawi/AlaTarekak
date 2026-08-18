import 'package:alatarekak/features/policy/data/model/policy_content_model.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'policies_fixture.dart';

/// قراءة `GET /policies`.
///
/// السياسة صارت تُحرَّر من لوحة الأدمن، فالمحتوى يكتبه إنسان: قد يصل قسم
/// بلا نقاط، أو مجموعة أسئلة فارغة، أو أيقونة باسم لا نعرفه. وثيقة
/// قانونية لا يصحّ أن تنهار على شيء من ذلك — يُتجاوز الناقص ويُعرض
/// الباقي.

Map<String, dynamic> get _data =>
    Map<String, dynamic>.from(policiesResponseFixture['data'] as Map);

void main() {
  group('الرد الحقيقي', () {
    test('يُقرأ بكامل أجزائه', () {
      final content = PolicyContentModel.fromJson(_data);

      expect(content.privacy.sections, hasLength(2));
      expect(content.cancellation.sections, hasLength(2));
      expect(content.faq, hasLength(2));
      expect(content.privacy.lastUpdatedLabel, isNotEmpty);
    });

    test('الإعدادات تصل كما أرسلها الأدمن', () {
      final content = PolicyContentModel.fromJson(_data);
      final settings = _data['settings'] as Map;

      expect(content.settings.appName, settings['app_name']);
      expect(content.settings.contactEmail, settings['contact_email']);
      expect(content.settings.consentLabel, settings['consent_label']);
    });

    test('عناوين الأقسام ونصوصها تصل', () {
      final content = PolicyContentModel.fromJson(_data);
      final first = content.privacy.sections.first;

      expect(first.title, isNotEmpty);
      expect(first.intro ?? '', isNotEmpty);
    });

    test('الأسئلة تصل بسؤالها وجوابها', () {
      final content = PolicyContentModel.fromJson(_data);
      final group = content.faq.first;

      expect(group.title, isNotEmpty);
      expect(group.entries, isNotEmpty);
      expect(group.entries.first.question, isNotEmpty);
      expect(group.entries.first.answer, isNotEmpty);
    });

    test('ذهاباً وإياباً عبر الكاش بلا فقد', () {
      final original = PolicyContentModel.fromJson(_data);
      final restored =
          PolicyContentModel.fromJson(PolicyContentModel.toJson(original));

      expect(restored.privacy.sections.length, original.privacy.sections.length);
      expect(restored.faq.length, original.faq.length);
      expect(restored.settings.consentLabel, original.settings.consentLabel);
      expect(restored.faq.first.icon, original.faq.first.icon);
      expect(restored.privacy.sections.first.points,
          original.privacy.sections.first.points);
    });
  });

  group('الأيقونات', () {
    test('الأسماء المرسَلة فعلاً تُعرف كلها', () {
      final groups = (_data['faq'] as Map)['groups'] as List;
      for (final g in groups) {
        final name = (g as Map)['icon'] as String;
        expect(
          iconFromName(name),
          isNot(Icons.help_outline_rounded),
          reason: 'الاسم $name لا جدول له فسيظهر بأيقونة عامة',
        );
      }
    });

    test('اسم مجهول يعطي أيقونة عامة لا انهياراً', () {
      expect(iconFromName('لا_وجود_لها'), Icons.help_outline_rounded);
      expect(iconFromName(null), Icons.help_outline_rounded);
    });
  });

  group('محتوى ناقص من اللوحة', () {
    test('قسم بلا نقاط يُعرض بمقدّمته', () {
      final content = PolicyContentModel.fromJson({
        'privacy': {
          'sections': [
            {'title': 'من نحن', 'intro': 'نصّ تعريفي', 'points': []},
          ],
        },
      });

      expect(content.privacy.sections, hasLength(1));
      expect(content.privacy.sections.first.points, isEmpty);
      expect(content.privacy.sections.first.intro, 'نصّ تعريفي');
    });

    test('قسم فارغ تماماً يُسقَط', () {
      final content = PolicyContentModel.fromJson({
        'privacy': {
          'sections': [
            {'title': '  ', 'intro': null, 'points': []},
            {'title': 'قسم حقيقي'},
          ],
        },
      });

      expect(content.privacy.sections, hasLength(1));
      expect(content.privacy.sections.first.title, 'قسم حقيقي');
    });

    test('مجموعة أسئلة بلا أسئلة تُسقَط', () {
      final content = PolicyContentModel.fromJson({
        'faq': {
          'groups': [
            {'title': 'فارغة', 'icon': 'shield_outlined', 'entries': []},
            {
              'title': 'الحجز',
              'icon': 'event_seat_outlined',
              'entries': [
                {'question': 'س', 'answer': 'ج'}
              ],
            },
          ],
        },
      });

      expect(content.faq, hasLength(1));
      expect(content.faq.first.title, 'الحجز');
    });

    test('سؤال بلا جواب يُسقَط ويبقى الباقي', () {
      final content = PolicyContentModel.fromJson({
        'faq': {
          'groups': [
            {
              'title': 'الحجز',
              'entries': [
                {'question': 'بلا جواب'},
                {'question': 'س', 'answer': 'ج'},
              ],
            },
          ],
        },
      });

      expect(content.faq.first.entries, hasLength(1));
      expect(content.faq.first.entries.first.answer, 'ج');
    });
  });

  group('الرد الفارغ يعود إلى النسخة المدمجة', () {
    test('الإعدادات لا تصير فراغاً', () {
      final content = PolicyContentModel.fromJson(const {});
      final builtIn = PolicyContent.builtIn.settings;

      expect(content.settings.contactEmail, builtIn.contactEmail);
      expect(
        content.settings.consentLabel,
        builtIn.consentLabel,
        reason: 'سطر موافقة فارغ يجعل مربّع التسجيل بلا معنى',
      );
    });
  });
}
