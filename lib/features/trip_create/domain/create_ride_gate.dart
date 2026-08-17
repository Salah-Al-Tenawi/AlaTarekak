import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

/// ما يمنع المستخدم من إنشاء رحلة — يُفحَص **قبل** فتح معالج الإنشاء.
enum CreateRideBlock {
  /// لا مانع — يُسمح بالمتابعة.
  none,

  /// لم يبدأ التوثيق بعد.
  notVerified,

  /// طلب التوثيق قيد المراجعة — لا إجراء يملكه المستخدم الآن.
  verificationPending,

  /// طلب التوثيق مرفوض — يعيد التقديم.
  verificationRejected,

  /// موثّق لكن بلا سيارة في ملفه.
  noCar,
}

/// حارس إنشاء الرحلة.
///
/// كان المستخدم يُدخل الرحلة كاملة — الخريطة والمسار والموعد والمقاعد
/// والسعر ورقم التواصل — وعند الضغط على «إنشاء» يرفض الخادم بأنه غير موثّق
/// أو بلا سيارة. عمل يُهدر بالكامل لأجل شرط كان معلوماً من البداية.
///
/// الفحص هنا **دالة نقية** لا تلمس الشبكة ولا الواجهة، فتُختبَر وحدها.
class CreateRideGate {
  CreateRideGate._();

  /// شرط الخادم لإنشاء الرحلة: توثيق كسائق + نوع مركبة.
  ///
  /// [profile] قد يكون `null` إن لم يُحمَّل الملف أو فشل جلبه. في تلك الحالة
  /// **يُسمح بالمتابعة**: منع مستخدم مستوفٍ للشرط لأننا لم نقرأ ملفه أسوأ
  /// من تركه يصل إلى الخادم فيحسم هو.
  static CreateRideBlock check(ProfileEntity? profile) {
    if (profile == null) return CreateRideBlock.none;

    switch (profile.verification.trim().toLowerCase()) {
      case 'approved':
        break;
      case 'pending':
        return CreateRideBlock.verificationPending;
      case 'rejected':
        return CreateRideBlock.verificationRejected;
      default:
        return CreateRideBlock.notVerified;
    }

    // `car` لا يُبنى إلا حين يرسل الخادم `type_of_car`، لكن لا نتّكل على ذلك:
    // نوع فارغ أو مسافات بيضاء ليس مركبة
    final type = profile.car?.type?.trim();
    if (type == null || type.isEmpty) return CreateRideBlock.noCar;

    return CreateRideBlock.none;
  }

  /// عنوان الحوار.
  static String title(CreateRideBlock block) => switch (block) {
        CreateRideBlock.notVerified => 'حسابك غير موثّق',
        CreateRideBlock.verificationPending => 'طلب التوثيق قيد المراجعة',
        CreateRideBlock.verificationRejected => 'طلب التوثيق مرفوض',
        CreateRideBlock.noCar => 'لا توجد مركبة في حسابك',
        CreateRideBlock.none => '',
      };

  /// شرح السبب وما يفعله المستخدم.
  static String message(CreateRideBlock block) => switch (block) {
        CreateRideBlock.notVerified =>
          'توثيق الحساب كسائق شرط لإنشاء الرحلات. يستغرق الأمر دقائق: '
              'ترفع صورتَي هويتك ورخصة القيادة وفحص السيارة.',
        CreateRideBlock.verificationPending =>
          'مستنداتك وصلت وقيد المراجعة. تستغرق المراجعة ٢٤ إلى ٤٨ ساعة عمل، '
              'وستتمكّن من إنشاء الرحلات فور اعتمادها.',
        CreateRideBlock.verificationRejected =>
          'تم رفض طلب التوثيق، وإنشاء الرحلات يتطلّب حساباً موثّقاً. '
              'أعد رفع المستندات بصور واضحة.',
        CreateRideBlock.noCar =>
          'إنشاء الرحلة يتطلّب مركبة مسجَّلة في ملفك: نوعها ولونها وعدد '
              'مقاعدها. أضفها مرة واحدة وتُستخدم في كل رحلاتك.',
        CreateRideBlock.none => '',
      };

  /// نصّ زرّ الإجراء، أو `null` حين لا يملك المستخدم إجراءً (المراجعة).
  static String? actionLabel(CreateRideBlock block) => switch (block) {
        CreateRideBlock.notVerified => 'ابدأ التوثيق',
        CreateRideBlock.verificationRejected => 'إعادة التقديم',
        CreateRideBlock.noCar => 'أضف مركبتك',
        CreateRideBlock.verificationPending => null,
        CreateRideBlock.none => null,
      };
}
