import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import 'package:alatarekak/core/service/hive_services.dart';

/// ذاكرة «سبق أن أبلغتُ عن هذا» — محليّة بالضرورة لا بالاختيار.
///
/// الخادم لا يكشف تقارير الغياب في أي مسار `GET`: لا حقل في الحجز ولا في
/// الرحلة ولا مسار مستقلّ. فبلا هذه الذاكرة يبقى الزرّ مفتوحاً بعد بلاغ
/// ناجح، فيضغطه المستخدم ثانيةً ويصله 422.
///
/// **وهي ذاكرة ناقصة عن قصد**: تضيع بإعادة تثبيت التطبيق أو تسجيل الخروج
/// (تعيش في `cacheBox` الذي يُمسح عندئذ). وذلك مقبول لأن الخادم يمسك
/// الحقيقة النهائية: يردّ «already submitted» فيُقفَل الزرّ من جديد —
/// انظر [NoShowReport.isAlreadyReported].
class NoShowReportStore {
  NoShowReportStore._();

  static const String _key = 'no_show_reports';

  /// بلاغ الراكب عن سائق رحلة — مفتاحه الرحلة، فالراكب يبلّغ مرة واحدة
  /// عن الرحلة كلها.
  static String rideKey(int rideId) => 'ride:$rideId';

  /// بلاغ السائق عن راكب — مفتاحه الحجز، فلكل راكب حجزه وبلاغه.
  static String bookingKey(int bookingId) => 'booking:$bookingId';

  static Map<String, dynamic> _read() {
    // الصندوق قد لا يكون مفتوحاً — إقلاعٌ مبكر أو اختبار ويدجت لا يهيّئ
    // Hive. وقراءةُ كاشٍ لتلوين زرّ لا تصحّ أن تُسقط الشاشة، فالغياب
    // يعني «لا بلاغ سابق» ويحسم الخادم البقية بـ«already submitted».
    if (!Hive.isBoxOpen(HiveBoxes.cacheBoxName)) return {};

    final raw = HiveBoxes.cacheBox.get(_key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : {};
    } on FormatException {
      // كاش تالف لا يمنع الإبلاغ: يُعامَل كأن لا بلاغ سابق
      return {};
    }
  }

  /// هل أُبلغ عن هذا المفتاح من قبل؟
  static bool wasReported(String key) => _read().containsKey(key);

  /// متى أُبلغ — لعرض «حتى ~الساعة كذا» تقريبياً، إذ لا يرسل الخادم
  /// `expires_at`.
  static DateTime? reportedAt(String key) {
    final at = _read()[key];
    return at is String ? DateTime.tryParse(at) : null;
  }

  /// يُسجّل البلاغ. لا يرمي مهما حدث: البلاغ وصل الخادم فعلاً، وفشل
  /// الكتابة محلياً يستحقّ زرّاً يعود ظاهراً لا شاشةً تسقط.
  static Future<void> remember(String key, {DateTime? at}) async {
    try {
      if (!Hive.isBoxOpen(HiveBoxes.cacheBoxName)) return;
      final reports = _read()
        ..[key] = (at ?? DateTime.now()).toIso8601String();
      await HiveBoxes.cacheBox.put(_key, jsonEncode(reports));
    } catch (e) {
      assert(() {
        debugPrint('⚠️ NoShowReportStore: تعذّر حفظ البلاغ — $e');
        return true;
      }());
    }
  }

  /// للاختبارات ولتسجيل الخروج.
  static Future<void> clear() async {
    if (!Hive.isBoxOpen(HiveBoxes.cacheBoxName)) return;
    await HiveBoxes.cacheBox.delete(_key);
  }
}
