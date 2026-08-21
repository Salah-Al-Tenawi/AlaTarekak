/// قراءة ردّ بلاغ الغياب — وما يُبنى حوله من نقص الخادم.
///
/// الطرفان يبلّغان عن غياب بعضهما بعد الانطلاق، ولكلٍّ مهلةٌ للاعتراض.
/// ثلاث نهايات ممكنة: يُقبل البلاغ، أو يتبيّن أن الطرفين أبلغا فتُفتح
/// شكوى ولا عقوبة، أو يكون البلاغ مكرَّراً.
///
/// **الخادم لا يقول أيّها وقعت في حقل صريح.** الكونترولر يُسقط `conflict`
/// و`report_id` و`expires_at` و`complaint_id` رغم أن الخدمة تُرجعها، ولا
/// يوجد `GET` يكشف تقارير الغياب أصلاً. فالتمييز من نصّ الرسالة، وهو
/// حلٌّ التفافي مؤقّت — **جُمع كلّه هنا** ليُحذف من موضع واحد يوم يُصلَح
/// الخادم بدل تتبّعه في الشاشات.
library;

/// ما آل إليه البلاغ.
enum NoShowOutcome {
  /// قُبل البلاغ، وللطرف الآخر مهلةٌ للاعتراض.
  reported,

  /// الطرفان أبلغا: لا عقوبة تلقائية، وشكوى فُتحت يبتّ فيها الدعم.
  conflict,

  /// بلاغ مكرَّر — الخادم يردّه 422 وهو في المعنى نجاح متأخّر.
  alreadyReported,
}

class NoShowReport {
  NoShowReport._();

  // مهلة الاعتراض **لا تُثبَّت هنا**. كانت `Duration(hours: 2)` تُقال
  // للمستخدم نصّاً، ثمّ تبيّن أن ثابت الخادم `DISPUTE_MINUTES` في وضع
  // تجريب — دقيقتان لا ساعتان — بينما رسائله هو ما زالت تقول «ساعتان».
  // فالرقم الذي كنّا نعرضه مخطئ بعامل ستّين، وسيبقى مخطئاً بعد إعادة
  // الثوابت ما دام مكتوباً عندنا. لا نعرض مدّة حتى يُرسل الخادم
  // `expires_at` — وقد وعد به.

  /// ردّ التعارض يحمل النصّ نفسه في المسارين، ويأتي بـ 200 كالنجاح
  /// العادي — فلا يميّزه رمز الحالة ولا بنية الرد، بل عبارته وحدها.
  static bool isConflict(dynamic response) =>
      _messageOf(response).contains('both parties');

  /// «سبق أن أبلغت» يصل 422، وهو ليس خطأً: الحالة المطلوبة قائمة فعلاً.
  ///
  /// يقع كلما فُقدت الحالة المحلية — إعادة تثبيت التطبيق أو تسجيل خروج —
  /// لأنه لا مصدر حقيقة على الخادم يُسأل عنه. فيُعامَل كنجاح متأخّر:
  /// يُقفل الزرّ ولا تظهر رسالة حمراء على فعل تمّ.
  static bool isAlreadyReported(String message) =>
      message.toLowerCase().contains('already submitted');

  /// الدقائق المتبقية حتى تُفتح البوابة، من رسالة الرفض:
  /// «No-show reporting unlocks 1 hour after departure. 37 minute(s)
  /// remaining.» — `null` إن لم تكن الرسالة من هذا النوع.
  ///
  /// تُقرأ من الخادم لا تُحسب محلياً: ساعة الجهاز قد تسبق أو تتأخّر،
  /// والخادم هو من يفتح البوابة فعلاً.
  static int? minutesUntilUnlock(String message) {
    final lower = message.toLowerCase();
    if (!lower.contains('unlocks')) return null;

    final match = RegExp(r'(\d+)\s*minute').firstMatch(lower);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// نصّ الرسالة من ردٍّ قد يكون خريطة أو نصّاً — ردود هذين المسارين
  /// تصل `dynamic` من طبقة الشبكة.
  static String _messageOf(dynamic response) {
    if (response is Map) {
      final message = response['message'];
      if (message is String) return message.toLowerCase();
    }
    return response?.toString().toLowerCase() ?? '';
  }
}
