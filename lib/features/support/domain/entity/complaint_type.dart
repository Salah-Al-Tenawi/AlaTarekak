import 'package:flutter/material.dart';

/// أنواع الشكاوى — القيم مطابقة تماماً لقيم الباك إند (snake_case).
/// قيمة غير معروفة ← other دفاعياً.
enum ComplaintType {
  tripSafety('trip_safety'),
  driverBehavior('driver_behavior'),
  passengerBehavior('passenger_behavior'),
  rideCancellation('ride_cancellation'),
  financialIssue('financial_issue'),
  accountIssue('account_issue'),
  technicalIssue('technical_issue'),

  /// تعارض تقارير الغياب — **يولّده النظام ولا يرسله المستخدم**.
  ///
  /// حين يبلّغ الطرفان كلٌّ عن غياب الآخر، لا عقوبة تلقائية: تُفتح شكوى
  /// يبتّ فيها الدعم. و`POST /complaints` لا يقبل هذه القيمة (422)، فهي
  /// خارج [userSubmittable] — انظرها.
  noShow('no_show'),

  other('other');

  /// القيمة المرسلة/المستقبلة من الـ API
  final String apiValue;
  const ComplaintType(this.apiValue);

  /// ما يجوز للمستخدم اختياره في شاشة «إرسال شكوى».
  ///
  /// [noShow] مستثنى: الخادم يرفضه بـ 422 لأنه من صنعه هو. وعرضه في
  /// الشبكة كان سيقدّم للمستخدم خياراً يفشل عند الإرسال.
  static List<ComplaintType> get userSubmittable =>
      values.where((t) => t != ComplaintType.noShow).toList();

  static ComplaintType fromString(String? value) {
    return ComplaintType.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => ComplaintType.other,
    );
  }

  String get label {
    switch (this) {
      case ComplaintType.tripSafety:
        return 'أمان الرحلة';
      case ComplaintType.driverBehavior:
        return 'سلوك السائق';
      case ComplaintType.passengerBehavior:
        return 'سلوك الراكب';
      case ComplaintType.rideCancellation:
        return 'إلغاء الرحلة';
      case ComplaintType.financialIssue:
        return 'مشكلة مالية';
      case ComplaintType.accountIssue:
        return 'مشكلة في الحساب';
      case ComplaintType.technicalIssue:
        return 'عطل تقني';
      case ComplaintType.noShow:
        return 'تعارض تقارير الغياب';
      case ComplaintType.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintType.tripSafety:
        return Icons.shield_outlined;
      case ComplaintType.driverBehavior:
        return Icons.directions_car_outlined;
      case ComplaintType.passengerBehavior:
        return Icons.person_outline_rounded;
      case ComplaintType.rideCancellation:
        return Icons.cancel_outlined;
      case ComplaintType.financialIssue:
        return Icons.account_balance_wallet_outlined;
      case ComplaintType.accountIssue:
        return Icons.manage_accounts_outlined;
      case ComplaintType.technicalIssue:
        return Icons.phone_android_outlined;
      case ComplaintType.noShow:
        return Icons.person_off_outlined;
      case ComplaintType.other:
        return Icons.help_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintType.tripSafety:
        return const Color(0xFFD32F2F);
      case ComplaintType.driverBehavior:
        return const Color(0xFF1565C0);
      case ComplaintType.passengerBehavior:
        return const Color(0xFF6A1B9A);
      case ComplaintType.rideCancellation:
        return const Color(0xFFE65100);
      case ComplaintType.financialIssue:
        return const Color(0xFF2E7D32);
      case ComplaintType.accountIssue:
        return const Color(0xFF00838F);
      case ComplaintType.technicalIssue:
        return const Color(0xFF558B2F);
      case ComplaintType.noShow:
        return const Color(0xFFAD1457);
      case ComplaintType.other:
        return const Color(0xFF546E7A);
    }
  }

  Color get bgColor {
    switch (this) {
      case ComplaintType.tripSafety:
        return const Color(0xFFFFEBEE);
      case ComplaintType.driverBehavior:
        return const Color(0xFFE3F2FD);
      case ComplaintType.passengerBehavior:
        return const Color(0xFFF3E5F5);
      case ComplaintType.rideCancellation:
        return const Color(0xFFFFF3E0);
      case ComplaintType.financialIssue:
        return const Color(0xFFE8F5E9);
      case ComplaintType.accountIssue:
        return const Color(0xFFE0F7FA);
      case ComplaintType.technicalIssue:
        return const Color(0xFFF1F8E9);
      case ComplaintType.noShow:
        return const Color(0xFFFCE4EC);
      case ComplaintType.other:
        return const Color(0xFFECEFF1);
    }
  }
}
