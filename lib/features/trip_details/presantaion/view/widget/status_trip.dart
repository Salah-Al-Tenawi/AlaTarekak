import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

class StatusInfo {
  final String text;
  final Color color;

  /// false حين لا تُطابَق الحالة أو تصل فارغة.
  ///
  /// بعض المسارات لا ترسل حالة الرحلة أصلاً، فكان يظهر للمستخدم مربّع
  /// «غير معروف» — وهو ضجيج لا معلومة. تتيح هذه الراية للواجهة أن تُخفي
  /// الشارة بدل عرض قيمة لا نملكها.
  final bool isKnown;

  StatusInfo(this.text, this.color, {this.isKnown = true});
}

StatusInfo getStatusInfo(String? status) {
  final normalized = status?.trim().toLowerCase() ?? "";

  switch (normalized) {
    case 'pending':
      return StatusInfo('قيد الانتظار', MyColors.accent);
    case 'awaiting_confirmation':
      return StatusInfo('بانظار تأكيد الوصول', MyColors.warning);
    case 'accepted':
      return StatusInfo('مقبول', MyColors.success);
    case 'rejected':
      return StatusInfo('مرفوض', MyColors.error);
    case 'confirmed':
      return StatusInfo('مؤكد', MyColors.primary);
    case 'cancelled':
      return StatusInfo('ملغي', MyColors.error);
    case 'no_show':
      return StatusInfo('لم يحضر', MyColors.textSecondary);
    case 'completed':
      return StatusInfo('تم', MyColors.blue);
    case 'full':
      return StatusInfo('ممتلئة', MyColors.textSecondary);
    case 'active':
      return StatusInfo('متاح', MyColors.success);
    case 'finished':
      return StatusInfo('انتهت الرحلة', MyColors.blue);

    default:
      return StatusInfo('غير معروف', MyColors.textSecondary, isKnown: false);
  }
}
