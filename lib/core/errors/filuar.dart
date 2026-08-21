/// معلومات الحظر المرفقة مع خطأ USER_BANNED (403).
class BanInfo {
  final String reason;
  final String type; // temporary | permanent
  final String? expiresAt;

  const BanInfo({
    required this.reason,
    required this.type,
    this.expiresAt,
  });

  bool get isPermanent => type == 'permanent';

  factory BanInfo.fromJson(Map<String, dynamic> json) {
    return BanInfo(
      reason: json['reason']?.toString() ?? '',
      type: json['type']?.toString() ?? 'permanent',
      expiresAt: json['expires_at']?.toString(),
    );
  }
}

/// كائن الفشل الموحّد — يفهم كل أشكال أخطاء الباك إند:
/// - المغلف A: {"success": false, "message"/"errors": ...}
/// - المغلف B: {"status": "error", "message": ..., "code": ...}
/// - شكل Laravel الافتراضي للـ 422: {"message": "...", "errors": {...}} بدون success/status
class Filuar {
  /// رسالة الباك إند الخام (إنجليزية غالباً) — للمطابقة البرمجية فقط،
  /// لا تُعرض للمستخدم مباشرة. استخدم HandelErorrMessage للعربية.
  final String message;

  /// كود برمجي مثل TOKEN_INVALID, USER_BANNED, INVALID_CREDENTIALS (إن وجد).
  final String? code;

  /// أخطاء التحقق لكل حقل: {field: [messages]} (للـ 422).
  final Map<String, List<String>>? errors;

  /// تفاصيل الحظر (فقط مع USER_BANNED).
  final BanInfo? ban;

  /// رمز حالة HTTP كما ردّه الخادم — 422، 500، 401…
  ///
  /// يُذيَّل به النصّ العربي المعروض للمستخدم: «تعذّر الاتصال بالخادم
  /// (500)». الرسالة وحدها لا تكفي حين يتصل المستخدم بالدعم — الرمز
  /// يقود إلى السطر الذي فشل في سجلّ الخادم.
  ///
  /// `null` لأعطال لا رمز لها: انقطاع الشبكة، مهلة الاتصال، إلغاء الطلب.
  final int? statusCode;

  const Filuar({
    required this.message,
    this.code,
    this.errors,
    this.ban,
    this.statusCode,
  });

  bool get isValidation => errors != null && errors!.isNotEmpty;

  /// أول رسالة خطأ تحقق (مفيدة كـ fallback).
  String? get firstFieldError =>
      isValidation ? errors!.values.first.firstOrNull : null;

  /// هل فشل الحقل المحدد في التحقق؟
  bool hasFieldError(String field) => errors?.containsKey(field) ?? false;

  factory Filuar.fromJson(Map<String, dynamic> json, {int? statusCode}) {
    // الرسالة: message أو error.message أو error
    String message = '';
    final rawMessage = json['message'];
    if (rawMessage is String && rawMessage.isNotEmpty) {
      message = rawMessage;
    } else {
      final rawError = json['error'];
      if (rawError is Map<String, dynamic>) {
        message = rawError['message']?.toString() ?? '';
      } else if (rawError is String) {
        message = rawError;
      }
    }

    // أخطاء التحقق {field: [msgs]} — تغطي الشكلين (مع أو بدون مفتاح envelope)
    Map<String, List<String>>? errors;
    final rawErrors = json['errors'];
    if (rawErrors is Map<String, dynamic>) {
      errors = rawErrors.map((field, msgs) {
        if (msgs is List) {
          return MapEntry(field, msgs.map((m) => m.toString()).toList());
        }
        return MapEntry(field, [msgs.toString()]);
      });
      if (message.isEmpty && errors.isNotEmpty) {
        message = errors.values.first.first;
      }
    }

    // معلومات الحظر
    BanInfo? ban;
    final rawBan = json['ban'];
    if (rawBan is Map<String, dynamic>) {
      ban = BanInfo.fromJson(rawBan);
    }

    return Filuar(
      message: message.isEmpty ? 'حدث خطأ غير متوقع' : message,
      code: json['code']?.toString(),
      errors: errors,
      ban: ban,
      statusCode: statusCode,
    );
  }
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
