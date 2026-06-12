/// الباك إند يستخدم مغلفين مختلفين (راجع مستند المواصفات §0.2):
///   A: {"success": true/false, ...}   — Profile, Rides, Bookings, Chat, Wallet...
///   B: {"status": "success"/"error", ...} — Auth, ride lifecycle, Complaints...
/// هذا الكلاس يوحّد التعامل معهما حتى لا يفترض أي Repo شكلاً واحداً.
class ApiEnvelope {
  ApiEnvelope._();

  /// هل الاستجابة ناجحة؟ يتسامح مع المغلفين معاً.
  static bool isOk(dynamic json) {
    if (json is! Map<String, dynamic>) return false;
    return json['success'] == true || json['status'] == 'success';
  }

  /// رسالة الباك إند الخام (إن وجدت) — للمطابقة البرمجية لا للعرض.
  static String? message(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    final m = json['message'];
    return m is String && m.isNotEmpty ? m : null;
  }

  /// محتوى data أياً كان شكله (قائمة أو خريطة).
  static dynamic data(dynamic json) {
    if (json is! Map<String, dynamic>) return null;
    return json['data'];
  }
}
