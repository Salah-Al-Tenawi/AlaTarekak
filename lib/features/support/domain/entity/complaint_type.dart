import 'package:flutter/material.dart';

enum ComplaintType {
  safety,
  driverBehavior,
  passengerBehavior,
  tripCancellation,
  financial,
  account,
  technical,
  other;

  static ComplaintType fromString(String value) {
    return ComplaintType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplaintType.other,
    );
  }

  String get apiValue => name;

  String get label {
    switch (this) {
      case ComplaintType.safety:
        return 'أمان الرحلة';
      case ComplaintType.driverBehavior:
        return 'سلوك السائق';
      case ComplaintType.passengerBehavior:
        return 'سلوك الراكب';
      case ComplaintType.tripCancellation:
        return 'إلغاء الرحلة';
      case ComplaintType.financial:
        return 'مشكلة مالية';
      case ComplaintType.account:
        return 'مشكلة في الحساب';
      case ComplaintType.technical:
        return 'عطل تقني';
      case ComplaintType.other:
        return 'أخرى';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintType.safety:
        return Icons.shield_outlined;
      case ComplaintType.driverBehavior:
        return Icons.directions_car_outlined;
      case ComplaintType.passengerBehavior:
        return Icons.person_outline_rounded;
      case ComplaintType.tripCancellation:
        return Icons.cancel_outlined;
      case ComplaintType.financial:
        return Icons.account_balance_wallet_outlined;
      case ComplaintType.account:
        return Icons.manage_accounts_outlined;
      case ComplaintType.technical:
        return Icons.phone_android_outlined;
      case ComplaintType.other:
        return Icons.help_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintType.safety:
        return const Color(0xFFD32F2F);
      case ComplaintType.driverBehavior:
        return const Color(0xFF1565C0);
      case ComplaintType.passengerBehavior:
        return const Color(0xFF6A1B9A);
      case ComplaintType.tripCancellation:
        return const Color(0xFFE65100);
      case ComplaintType.financial:
        return const Color(0xFF2E7D32);
      case ComplaintType.account:
        return const Color(0xFF00838F);
      case ComplaintType.technical:
        return const Color(0xFF558B2F);
      case ComplaintType.other:
        return const Color(0xFF546E7A);
    }
  }

  Color get bgColor {
    switch (this) {
      case ComplaintType.safety:
        return const Color(0xFFFFEBEE);
      case ComplaintType.driverBehavior:
        return const Color(0xFFE3F2FD);
      case ComplaintType.passengerBehavior:
        return const Color(0xFFF3E5F5);
      case ComplaintType.tripCancellation:
        return const Color(0xFFFFF3E0);
      case ComplaintType.financial:
        return const Color(0xFFE8F5E9);
      case ComplaintType.account:
        return const Color(0xFFE0F7FA);
      case ComplaintType.technical:
        return const Color(0xFFF1F8E9);
      case ComplaintType.other:
        return const Color(0xFFECEFF1);
    }
  }
}
