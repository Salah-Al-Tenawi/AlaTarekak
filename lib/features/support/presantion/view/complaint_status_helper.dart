import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class ComplaintStatusCfg {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const ComplaintStatusCfg(this.label, this.icon, this.color, this.bg);
}

ComplaintStatusCfg complaintStatusConfig(String status) {
  switch (status) {
    case 'resolved':
      return ComplaintStatusCfg(
        'تم الحل',
        Icons.check_circle_outline_rounded,
        MyColors.success,
        MyColors.successLight,
      );
    case 'rejected':
      return ComplaintStatusCfg(
        'مرفوض',
        Icons.cancel_outlined,
        MyColors.error,
        MyColors.errorLight,
      );
    case 'pending':
      return ComplaintStatusCfg(
        'قيد المراجعة',
        Icons.hourglass_empty_rounded,
        MyColors.warning,
        MyColors.warningLight,
      );
    case 'unread':
    default:
      return const ComplaintStatusCfg(
        'لم تتم المراجعة بعد',
        Icons.mark_email_unread_outlined,
        Color(0xFF1565C0),
        Color(0xFFE3F2FD),
      );
  }
}
