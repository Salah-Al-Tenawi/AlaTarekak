import 'package:alatarekak/features/policy/text/pollicy_text.dart';
import 'package:alatarekak/features/support/domain/entity/faq_entry.dart';

/// إعدادات الجهة المالكة — تظهر داخل نصّ السياسة وفي سطر الموافقة.
class PolicySettings {
  final String company;
  final String appName;
  final String contactEmail;
  final String contactPhone;
  final String contactAddress;

  /// سطر الموافقة الصريحة في شاشة إنشاء الحساب.
  final String consentLabel;

  const PolicySettings({
    required this.company,
    required this.appName,
    required this.contactEmail,
    required this.contactPhone,
    required this.contactAddress,
    required this.consentLabel,
  });
}

/// وثيقة واحدة: الخصوصية أو الإلغاء.
class PolicyDocument {
  final String lastUpdatedLabel;
  final List<PolicySection> sections;

  const PolicyDocument({
    required this.lastUpdatedLabel,
    required this.sections,
  });
}

/// كل ما يرسله `GET /policies`: الإعدادات ووثيقتان والأسئلة الشائعة.
///
/// صارت السياسة تُحرَّر من لوحة الأدمن (2026-08-18) بعد أن كانت نصّاً
/// مكتوباً في التطبيق. النصّ المكتوب باقٍ في [PolicyText] و[FaqData]
/// لكن **بصفته احتياطاً لا مصدراً**: وثيقة قانونية يجب أن تُعرض حتى بلا
/// شبكة — شاشة إنشاء الحساب تشترط الموافقة عليها، فلو تعذّر تحميلها
/// لتعذّر التسجيل نفسه.
class PolicyContent {
  final PolicySettings settings;
  final PolicyDocument privacy;
  final PolicyDocument cancellation;
  final List<FaqGroup> faq;

  const PolicyContent({
    required this.settings,
    required this.privacy,
    required this.cancellation,
    required this.faq,
  });

  /// النسخة المدمجة في التطبيق — آخر ما نعرفه حين لا كاش ولا شبكة.
  static PolicyContent get builtIn => PolicyContent(
        settings: const PolicySettings(
          company: PolicyText.company,
          appName: PolicyText.appName,
          contactEmail: PolicyText.contactEmail,
          contactPhone: PolicyText.contactPhone,
          contactAddress: PolicyText.contactAddress,
          consentLabel: PolicyText.consentLabel,
        ),
        privacy: const PolicyDocument(
          lastUpdatedLabel: PolicyText.lastUpdated,
          sections: PolicyText.privacy,
        ),
        cancellation: const PolicyDocument(
          lastUpdatedLabel: PolicyText.lastUpdated,
          sections: PolicyText.cancellation,
        ),
        faq: FaqData.groups,
      );
}
