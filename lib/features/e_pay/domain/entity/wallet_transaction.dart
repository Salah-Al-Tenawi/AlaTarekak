import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

/// حركة واحدة في كشف حساب المحفظة.
///
/// ⚠️ الخادم يرسل كل المبالغ **نصوصاً** بخانتين عشريتين ("-5000.00")
/// لا أرقاماً، فتُقرأ بـ double.parse لا int.parse.
class WalletTransaction {
  final int id;
  final String type;
  final double amount;
  final double balanceAfter;
  final String description;
  final String? reference;
  final DateTime? createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.balanceAfter,
    required this.description,
    this.reference,
    this.createdAt,
  });

  /// حركات بقيمة صفر هي سجلّات تدقيق لا حركات مالية: تأجيل الرسم كديْن،
  /// وإلغاء دين مؤجَّل، وتسجيل عدم الاسترداد. تُعرض بتنسيق مختلف حتى لا
  /// يظنّها المستخدم خصماً أو إيداعاً.
  bool get isAuditOnly => amount == 0;

  bool get isCredit => amount > 0;

  /// معرّف الرحلة أو الحجز المرتبط (reference بصيغة "ride:7").
  int? get referenceId {
    final parts = reference?.split(':');
    return parts != null && parts.length == 2 ? int.tryParse(parts[1]) : null;
  }

  /// وصف عربي للنوع — وصف الخادم إنجليزي ولا يُعرض للمستخدم.
  String get label => _labels[type] ?? 'حركة على المحفظة';

  static const Map<String, String> _labels = {
    'cash_ride_creation_fee': 'رسوم إنشاء رحلة نقدية',
    'cash_ride_fee_deferred': 'تأجيل رسوم الإنشاء كديْن',
    'cash_ride_fee_refund': 'استرداد رسوم إنشاء',
    'cash_ride_fee_debt_cancelled': 'إلغاء ديْن مؤجَّل',
    'cash_ride_fee_no_refund': 'لا استرداد — إلغاء متأخر',
    'cash_ride_debt_cleared': 'سداد الرسوم المستحقّة',
    'charge': 'شحن رصيد',
    'withdraw': 'سحب رصيد',
    'booking_payment': 'دفع قيمة حجز',
    'booking_refund': 'استرداد قيمة حجز',
    'ride_earning': 'أرباح رحلة',
  };

  IconData get icon {
    if (isAuditOnly) return Icons.receipt_long_outlined;
    return isCredit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
  }

  Color get color {
    if (isAuditOnly) return MyColors.textHint;
    return isCredit ? MyColors.success : MyColors.error;
  }
}

/// صفحة من كشف الحساب.
///
/// [balance] و[cashRideDebt] يأتيان داخل `meta` نفسه الذي يحمل حقول
/// الترقيم — فـ meta ليس للترقيم وحده.
class WalletStatement {
  final List<WalletTransaction> items;
  final double balance;
  final double cashRideDebt;
  final int currentPage;
  final int lastPage;
  final int total;

  const WalletStatement({
    required this.items,
    required this.balance,
    required this.cashRideDebt,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  /// على السائق رسوم مستحقّة تمنعه من إنشاء رحلات نقدية جديدة.
  bool get hasDebt => cashRideDebt > 0;
}
