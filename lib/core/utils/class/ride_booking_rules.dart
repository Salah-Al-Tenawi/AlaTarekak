/// متى تُحجز الرحلة ومتى لا تُحجز.
///
/// **الخادم لا يحرس هذا.** أخطاء `POST /rides/{id}/book` في مواصفة الـAPI
/// تغطّي التوثيق ونقاط الثقة وحجز السائق رحلته وتكرار الحجز وعدد المقاعد
/// والرقم والرصيد — ولا شيء عن موعد الانطلاق ولا عن حالة الرحلة. فمن بحث
/// فوجد رحلة انطلقت أمس واستطاع حجز مقعد فيها، ومن فتح رحلة ألغاها سائقها
/// كذلك.
///
/// فالحراسة هنا. وهي **حراسة عرض لا استبدال للخادم**: تمنع طلباً لا معنى
/// له، والخادم يبقى المرجع في كل ما يعرفه هو.
library;

import 'package:alatarekak/core/utils/class/ride_time_rules.dart';

/// سبب منع الحجز — مرتّب بأسبقيته.
enum BookingBlock {
  /// ألغى السائق رحلته.
  cancelled,

  /// انتهت الرحلة أو اكتملت.
  finished,

  /// حلّ موعد الانطلاق أو مضى — **العطل الذي لا يحرسه الخادم إطلاقاً**.
  departed,

  /// لا مقاعد.
  full,
}

const _cancelledStatuses = {'cancelled', 'canceled', 'no_show'};
const _finishedStatuses = {'finished', 'completed'};

/// انطلقت فعلاً — بإعلان السائق لا بمرور الموعد.
///
/// `launched` اسمها عند الخادم، و`awaiting_confirmation` اسمها القديم.
/// وهي تُحسم قبل الموعد: سائق أعلن انطلاقه مبكّراً ترفض رحلتُه الحجز
/// بينما ساعةُ التطبيق ترى الموعد لم يحن بعد، فيُعرض زرّ «احجز» على
/// رحلة يردّها الخادم.
const _launchedStatuses = {'launched', 'awaiting_confirmation'};

/// انتهت الرحلة أو أُلغيت — لم يعد يُنتظَر منها شيء.
///
/// **ليست `!active`**: الرحلة الممتلئة (`full`) رحلة قائمة لم تنطلق بعد،
/// وحشرُها هنا يُخفي عن سائقها إجراءات هو بحاجة إليها.
///
/// يُبنى عليها إخفاء بلاغ الغياب: الخادم نفسه يردّه على رحلة انتهت
/// («cannot report no-show for a ride with status»)، فعرضُ زرٍّ يقود إلى
/// رفضٍ مؤكَّد وعدٌ كاذب.
bool isRideOver(String status) {
  final normalized = status.trim().toLowerCase();
  return _cancelledStatuses.contains(normalized) ||
      _finishedStatuses.contains(normalized);
}

/// لماذا لا تُحجز هذه الرحلة — `null` إن كانت تقبل الحجز.
///
/// الأسبقية مقصودة: «ألغيت» أنفع للمستخدم من «انطلقت» على رحلة ألغيت قبل
/// موعدها بيوم، و«انطلقت» أنفع من «ممتلئة» على رحلة مضى موعدها.
BookingBlock? bookingBlockFor({
  required String status,
  required DateTime departure,
  DateTime? now,
}) {
  final normalized = status.trim().toLowerCase();

  if (_cancelledStatuses.contains(normalized)) return BookingBlock.cancelled;
  if (_finishedStatuses.contains(normalized)) return BookingBlock.finished;
  if (_launchedStatuses.contains(normalized) ||
      RideTimeRules.hasDeparted(departure, now: now)) {
    return BookingBlock.departed;
  }

  // الامتلاء يُقرأ من حالة الرحلة التي يضبطها الخادم، لا من عدّاد
  // المقاعد: العدّاد قد يصل صفراً لأن المسار سمّى الحقل باسم لا نقرؤه،
  // فيُمنع الراكب من حجز رحلة فيها مقاعد فعلاً.
  if (normalized == 'full') return BookingBlock.full;

  return null;
}

extension BookingBlockX on BookingBlock {
  /// نصّ الزرّ — يقول الحال، ولا يَعِد بفعل لا يقع.
  String get label => switch (this) {
        BookingBlock.cancelled => 'أُلغيت الرحلة',
        BookingBlock.finished => 'انتهت الرحلة',
        BookingBlock.departed => 'انطلقت الرحلة',
        BookingBlock.full => 'الرحلة ممتلئة',
      };

  /// عنوان الحوار الذي يشرح المنع.
  String get title => switch (this) {
        BookingBlock.cancelled => 'رحلة ملغاة',
        BookingBlock.finished => 'رحلة منتهية',
        BookingBlock.departed => 'انطلقت الرحلة',
        BookingBlock.full => 'لا مقاعد متاحة',
      };

  /// الشرح — يقول لماذا، ويقترح ما يفعله المستخدم بعده.
  String get message => switch (this) {
        BookingBlock.cancelled =>
          'ألغى السائق هذه الرحلة. ابحث عن رحلة أخرى على المسار نفسه.',
        BookingBlock.finished =>
          'انتهت هذه الرحلة ولم تعد تقبل الحجز. ابحث عن رحلة قادمة على '
              'المسار نفسه.',
        BookingBlock.departed =>
          'مضى موعد انطلاق هذه الرحلة، فلم تعد تقبل الحجز. ابحث عن رحلة '
              'قادمة على المسار نفسه.',
        BookingBlock.full =>
          'حُجزت كل مقاعد هذه الرحلة. جرّب رحلة أخرى على المسار نفسه.',
      };
}
