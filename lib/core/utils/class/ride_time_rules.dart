/// القواعد الزمنية لإجراءات الرحلة والحجز.
///
/// كانت مبعثرة في أربع شاشات بصيغ مختلفة — «هل انطلقت؟» تُحسب هنا بـ
/// `inSeconds <= 0` وهناك بمقارنة أخرى — فاختلف سلوك الأزرار بين شاشة
/// وأخرى على الرحلة نفسها.
///
/// **دوال نقية** تأخذ [now] اختيارياً، فتُختبَر بلا انتظار ولا ساعة نظام.
class RideTimeRules {
  RideTimeRules._();

  /// لا يُبلَّغ عن غياب أحد إلا بعد دقيقة من موعد الانطلاق.
  ///
  /// كانت ساعة — «التأخّر نصف ساعة زحمة سير لا غياب» — ثمّ قُصّرت بقرار
  /// صريح إلى دقيقة: الرحلات هنا داخل المدينة وبين المدن القريبة، ومن
  /// وقف عند الموعد فلم يجد أحداً لا ينتظر ساعة ليقول ذلك.
  static const Duration noShowDelay = Duration(minutes: 1);

  static DateTime _now(DateTime? now) => now ?? DateTime.now();

  /// حلّ موعد الانطلاق أو مضى.
  static bool hasDeparted(DateTime departure, {DateTime? now}) =>
      !_now(now).isBefore(departure);

  /// يُسمح بالإلغاء ما دامت الرحلة لم تنطلق — **بلا مهلة مسبقة**.
  ///
  /// جُرّبت مهلة (نصف ساعة ثم ساعة قبل الموعد) ثمّ أُلغيت بقرار صريح:
  /// ظرفٌ طارئ قبل الانطلاق بدقائق يقع فعلاً، ومنع الإلغاء حينها يدفع
  /// الطرفين إلى عدم الحضور بلا إخطار — وهو أسوأ للطرف الآخر من إلغاء
  /// متأخّر يصله إشعاره.
  ///
  /// وهي القاعدة نفسها للطرفين: إلغاء السائق رحلته، وإلغاء الراكب حجزه.
  static bool canCancelRide(DateTime departure, {DateTime? now}) =>
      !hasDeparted(departure, now: now);

  /// يُسمح بالإبلاغ عن عدم الحضور: بعد الانطلاق بـ [noShowDelay].
  static bool canReportNoShow(DateTime departure, {DateTime? now}) =>
      !_now(now).isBefore(departure.add(noShowDelay));

  /// ما بقي حتى تُفتح بوابة الإبلاغ — `null` إن فُتحت.
  ///
  /// الزرّ **يُخفى** ما دامت هذه المدّة قائمة: بلاغ الغياب معروضاً على
  /// حجز مؤكَّد لم تنطلق رحلته بعد يقلق الطرفين ولا يفيد أحداً، والمهلة
  /// دقيقة واحدة فلا يطول الغياب حتى يبحث عنه أحد. وهي تقدير محليّ:
  /// الخادم هو من يفتح البوابة فعلاً ورسالته تحمل الدقائق الباقية عنده.
  static Duration? untilNoShowGate(DateTime departure, {DateTime? now}) {
    final gate = departure.add(noShowDelay);
    final current = _now(now);
    return current.isBefore(gate) ? gate.difference(current) : null;
  }
}
