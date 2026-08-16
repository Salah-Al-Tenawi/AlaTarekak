import 'package:alatarekak/features/e_pay/domain/entity/wallet_transaction.dart';

/// تفكيك كشف الحساب.
///
/// ⚠️ هذا المسار لا يستخدم أياً من مغلَّفي التطبيق (`success` / `status`):
/// يعيد `data` + `links` + `meta` مباشرة بنمط JsonResource. لذلك لا
/// يُمرَّر على `ApiEnvelope.isOk` — وصول الرد بلا استثناء يعني نجاحه.
///
/// وكل المبالغ تصل **نصوصاً** بخانتين عشريتين، فتُحوَّل هنا مرة واحدة.
class WalletTransactionModel {
  WalletTransactionModel._();

  /// يقبل النصّ والرقم معاً: الخادم يرسل نصاً، لكن قبول الرقم يحمينا
  /// إن غيّر ذلك لاحقاً بلا إشعار.
  static double money(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  static WalletTransaction fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type']?.toString() ?? '',
      amount: money(json['amount']),
      balanceAfter: money(json['balance_after']),
      description: json['description']?.toString() ?? '',
      reference: json['reference']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')
          ?.toLocal(),
    );
  }

  /// تفكيك متسامح يقبل شكلَي الرد المتنازَعين.
  ///
  /// مواصفة الباك إند تصف: `{data: [...], meta: {balance, cash_ride_debt,
  /// current_page, ...}}`. لكن فريق لوحة الإدارة شغّل المسار مقابل الخادم
  /// الحقيقي فوجد مُرقِّم Laravel خاماً تحت المفتاح `transactions` وبلا
  /// كتلة `meta` إطلاقاً — وكلّفهم ذلك درج معاملات فارغاً دائماً.
  ///
  /// لمّا تعذّر حسم التناقض (الخادم متوقف وقت الكتابة) نقبل الشكلين:
  /// القائمة من `data` أو `transactions.data` أو `transactions`، وحقول
  /// الترقيم من `meta` أو من جذر المُرقِّم، والرصيد والدين من `meta` أو
  /// من الجذر. أيّ شكل شحنه الخادم يعمل بلا تعديل.
  static WalletStatement statementFromJson(Map<String, dynamic> json) {
    final tx = json['transactions'];
    // المُرقِّم: إمّا `transactions` نفسه، أو الجذر حين تُرسل `data`
    final paginator = tx is Map<String, dynamic> ? tx : json;

    final rawList = json['data'] is List
        ? json['data'] as List
        : (paginator['data'] is List
            ? paginator['data'] as List
            : (tx is List ? tx : const []));

    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    /// يقرأ من `meta` أولاً ثم من جذر المُرقِّم ثم من جذر الرد.
    dynamic pick(String key) =>
        meta[key] ?? paginator[key] ?? json[key];

    return WalletStatement(
      items: rawList.whereType<Map<String, dynamic>>().map(fromJson).toList(),
      balance: money(pick('balance')),
      cashRideDebt: money(pick('cash_ride_debt')),
      currentPage: (pick('current_page') as num?)?.toInt() ?? 1,
      lastPage: (pick('last_page') as num?)?.toInt() ?? 1,
      total: (pick('total') as num?)?.toInt() ?? rawList.length,
    );
  }
}
