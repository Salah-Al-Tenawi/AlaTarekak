import 'package:hive/hive.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';

/// تمييز محادثة الدعم عن محادثات السائقين والركّاب.
///
/// المحادثة مع الدعم عادية تماماً في الباك إند: تُفتح بـ POST /api/contact
/// ثم تُعامل كأي محادثة، وتظهر في القائمة باسم الموظف الشخصي فيصعب على
/// المستخدم إيجادها بين محادثات رحلاته.
///
/// نعتمد مصدرين للتعرّف عليها، فيكفي أحدهما:
///   1. الحقل `type` إن أرسله الخادم بقيمة support.
///   2. معرّف المحادثة الذي حفظناه محلياً لحظة فتحها من شاشة الدعم —
///      يعمل اليوم بلا انتظار أي تغيير من الباك إند.
class SupportConversation {
  SupportConversation._();

  static const String _key = 'support_conversation_id';

  /// الصندوق قد يكون غير مفتوح (إقلاع مبكر أو اختبار) — لا يجوز أن يُسقط
  /// قائمة المحادثات لأجل تمييز بصري.
  static Box<String>? get _box {
    try {
      return Hive.isBoxOpen(HiveBoxes.cacheBoxName) ? HiveBoxes.cacheBox : null;
    } catch (_) {
      return null;
    }
  }

  /// تُستدعى فور فتح محادثة الدعم من POST /api/contact.
  static Future<void> remember(int conversationId) async =>
      _box?.put(_key, '$conversationId');

  static int? get rememberedId {
    final raw = _box?.get(_key);
    return raw == null ? null : int.tryParse(raw);
  }

  /// هل هذه المحادثة هي محادثة الدعم؟
  static bool matches(ConversationEntity conv) =>
      conv.type.toLowerCase() == 'support' || conv.id == rememberedId;

  /// الاسم المعروض — نتجاهل اسم الموظف الشخصي لأن المستخدم يبحث عن
  /// «الدعم» لا عن شخص بعينه.
  static const String displayName = 'الدعم الفني';
}
