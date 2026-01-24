import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class StatusInfo {
  final String text;
  final Color color;

  StatusInfo(this.text, this.color);
}

StatusInfo getStatusInfo(String? status) {
  final normalized = status?.trim().toLowerCase() ?? "";

  switch (normalized) {
    case 'pending':
      return StatusInfo('قيد الانتظار', MyColors.accent);
    case 'awaiting_confirmation':
      return StatusInfo('بانظار تأكيد الوصول', Colors.amber.shade700);

    case 'confirmed':
      return StatusInfo('مؤكد', MyColors.primary);
    case 'cancelled':
      return StatusInfo('ملغي', Colors.red);
    case 'no_show':
      return StatusInfo('لم يحضر', MyColors.secondary);
    case 'completed':
      return StatusInfo('تم', Colors.blue.shade200);
    case 'full':
      return StatusInfo('ممتلئة', MyColors.secondary);
    case 'active':
      return StatusInfo('متاح', const Color(0xFF28A745));
    case 'finished':
      return StatusInfo('انتهت الرحلة', Colors.blue.shade200);

    default:
      return StatusInfo('غير معروف', MyColors.primaryText);
  }
}
