import 'package:flutter/material.dart';
import 'package:alatarekak/core/utils/functions/json_parse.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:alatarekak/features/support/domain/entity/faq_entry.dart';

/// تحويل رد `GET /policies` إلى [PolicyContent] وبالعكس (للكاش).
///
/// الشكل:
/// ```
/// { "status": "success", "data": {
///     "settings":     {company, app_name, contact_email, ...},
///     "privacy":      {last_updated_label, sections: [{title, intro, points}]},
///     "cancellation": {...},
///     "faq":          {groups: [{title, icon, entries: [{question, answer}]}]}
/// }}
/// ```
///
/// **متسامح عمداً:** السياسة يحرّرها إنسان من لوحة الأدمن، فقد يصل قسم
/// بلا نقاط أو مجموعة بلا أسئلة أو أيقونة باسم لا نعرفه. لا شيء من ذلك
/// يستحق شاشة خطأ في وثيقة قانونية — يُتجاوز الناقص ويُعرض الباقي.
class PolicyContentModel {
  PolicyContentModel._();

  static PolicyContent fromJson(Map<String, dynamic> data) {
    return PolicyContent(
      settings: _settings(asMap(data['settings']) ?? const {}),
      privacy: _document(asMap(data['privacy']) ?? const {}),
      cancellation: _document(asMap(data['cancellation']) ?? const {}),
      faq: _faq(asMap(data['faq']) ?? const {}),
    );
  }

  static Map<String, dynamic> toJson(PolicyContent content) => {
        'settings': {
          'company': content.settings.company,
          'app_name': content.settings.appName,
          'contact_email': content.settings.contactEmail,
          'contact_phone': content.settings.contactPhone,
          'contact_address': content.settings.contactAddress,
          'consent_label': content.settings.consentLabel,
        },
        'privacy': _documentToJson(content.privacy),
        'cancellation': _documentToJson(content.cancellation),
        'faq': {
          'groups': content.faq
              .map((g) => {
                    'title': g.title,
                    'icon': _iconNames[g.icon] ?? _fallbackIconName,
                    'entries': g.entries
                        .map((e) => {
                              'question': e.question,
                              'answer': e.answer,
                            })
                        .toList(),
                  })
              .toList(),
        },
      };

  // ─── الأجزاء ──────────────────────────────────────────────────────

  /// الحقل الغائب يعود إلى النسخة المدمجة لا إلى فراغ: بريد تواصل فارغ
  /// في سياسة خصوصية عيب، وسطر موافقة فارغ يجعل مربّع التسجيل بلا معنى.
  static PolicySettings _settings(Map<String, dynamic> json) {
    final f = PolicyContent.builtIn.settings;
    return PolicySettings(
      company: _text(json['company']) ?? f.company,
      appName: _text(json['app_name']) ?? f.appName,
      contactEmail: _text(json['contact_email']) ?? f.contactEmail,
      contactPhone: _text(json['contact_phone']) ?? f.contactPhone,
      contactAddress: _text(json['contact_address']) ?? f.contactAddress,
      consentLabel: _text(json['consent_label']) ?? f.consentLabel,
    );
  }

  static PolicyDocument _document(Map<String, dynamic> json) {
    final sections = (asList(json['sections']) ?? const [])
        .whereType<Map>()
        .map((e) => _section(Map<String, dynamic>.from(e)))
        .whereType<PolicySection>()
        .toList();

    return PolicyDocument(
      lastUpdatedLabel:
          _text(json['last_updated_label']) ?? PolicyText.lastUpdated,
      sections: sections,
    );
  }

  /// قسم بلا عنوان وبلا محتوى لا يُعرض — سطر فارغ في وثيقة يبدو عطلاً.
  static PolicySection? _section(Map<String, dynamic> json) {
    final title = _text(json['title']);
    final intro = _text(json['intro']);
    final points = (asList(json['points']) ?? const [])
        .map(_text)
        .whereType<String>()
        .toList(growable: false);

    if (title == null && intro == null && points.isEmpty) return null;

    return PolicySection(
      title: title ?? '',
      intro: intro,
      points: points,
    );
  }

  static List<FaqGroup> _faq(Map<String, dynamic> json) {
    return (asList(json['groups']) ?? const [])
        .whereType<Map>()
        .map((e) => _faqGroup(Map<String, dynamic>.from(e)))
        .whereType<FaqGroup>()
        .toList();
  }

  static FaqGroup? _faqGroup(Map<String, dynamic> json) {
    final entries = (asList(json['entries']) ?? const [])
        .whereType<Map>()
        .map((e) {
          final m = Map<String, dynamic>.from(e);
          final q = _text(m['question']);
          final a = _text(m['answer']);
          if (q == null || a == null) return null;
          return FaqEntry(q, a);
        })
        .whereType<FaqEntry>()
        .toList();

    // مجموعة بلا أسئلة عنوان يُفتح على فراغ
    if (entries.isEmpty) return null;

    return FaqGroup(
      title: _text(json['title']) ?? '',
      icon: iconFromName(_text(json['icon'])),
      entries: entries,
    );
  }

  static String? _text(dynamic value) {
    final s = (asString(value) ?? '').trim();
    return s.isEmpty ? null : s;
  }

  static Map<String, dynamic> _documentToJson(PolicyDocument doc) => {
        'last_updated_label': doc.lastUpdatedLabel,
        'sections': doc.sections
            .map((s) => {
                  'title': s.title,
                  'intro': s.intro,
                  'points': s.points,
                })
            .toList(),
      };
}

/// أيقونات مجموعات الأسئلة، مُسمّاة من لوحة الأدمن.
///
/// **جدول صريح لا `IconData(codePoint)`:** بناء الأيقونة من رقم يكسر
/// الإصدارات — `flutter build` يحذف كل أيقونة لا يراها مستعملة في
/// الشيفرة (tree-shaking)، فتظهر مربّعات فارغة في نسخة الإنتاج وحدها
/// بينما يعمل كل شيء في وضع التطوير.
const Map<String, IconData> _iconsByName = {
  'event_seat_outlined': Icons.event_seat_outlined,
  'cancel_outlined': Icons.cancel_outlined,
  'verified_user_outlined': Icons.verified_user_outlined,
  'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
  'directions_car_outlined': Icons.directions_car_outlined,
  'person_outline_rounded': Icons.person_outline_rounded,
  // أسماء إضافية محتملة من اللوحة
  'chat_bubble_outline_rounded': Icons.chat_bubble_outline_rounded,
  'shield_outlined': Icons.shield_outlined,
  'payments_outlined': Icons.payments_outlined,
  'info_outline_rounded': Icons.info_outline_rounded,
  'help_outline_rounded': Icons.help_outline_rounded,
};

const String _fallbackIconName = 'help_outline_rounded';

final Map<IconData, String> _iconNames = {
  for (final e in _iconsByName.entries) e.value: e.key,
};

/// اسم غير معروف يعطي أيقونة سؤال عامة — لا مربّعاً فارغاً ولا انهياراً.
IconData iconFromName(String? name) =>
    _iconsByName[name] ?? _iconsByName[_fallbackIconName]!;
