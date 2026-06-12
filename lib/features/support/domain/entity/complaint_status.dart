import 'package:flutter/material.dart';
import 'package:alatarekak/core/them/my_colors.dart';

/// حالات الشكوى — 5 قيم مطابقة للباك إند.
/// status_label الإنجليزي يُتجاهل، وstatus_color كلمة (yellow/blue/...)
/// تُربط بألوان الثيم محلياً. قيمة غير معروفة ← pending دفاعياً.
enum ComplaintStatus {
  pending('pending'),
  inReview('in_review'),
  escalated('escalated'),
  resolved('resolved'),
  closed('closed');

  final String apiValue;
  const ComplaintStatus(this.apiValue);

  static ComplaintStatus fromString(String? value) {
    return ComplaintStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => ComplaintStatus.pending,
    );
  }

  /// الحالات النشطة (لم تُغلق بعد)
  bool get isOpen => this == pending || this == inReview || this == escalated;

  bool get isTerminal => this == resolved || this == closed;

  String get label {
    switch (this) {
      case ComplaintStatus.pending:
        return 'قيد الانتظار';
      case ComplaintStatus.inReview:
        return 'قيد المراجعة';
      case ComplaintStatus.escalated:
        return 'مُصعّدة للإدارة';
      case ComplaintStatus.resolved:
        return 'تم الحل';
      case ComplaintStatus.closed:
        return 'مغلقة';
    }
  }

  IconData get icon {
    switch (this) {
      case ComplaintStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ComplaintStatus.inReview:
        return Icons.visibility_outlined;
      case ComplaintStatus.escalated:
        return Icons.trending_up_rounded;
      case ComplaintStatus.resolved:
        return Icons.check_circle_outline_rounded;
      case ComplaintStatus.closed:
        return Icons.lock_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ComplaintStatus.pending: // yellow
        return MyColors.warning;
      case ComplaintStatus.inReview: // blue
        return MyColors.blue;
      case ComplaintStatus.escalated: // orange
        return MyColors.accent;
      case ComplaintStatus.resolved: // green
        return MyColors.success;
      case ComplaintStatus.closed: // gray
        return MyColors.textSecondary;
    }
  }

  Color get bgColor {
    switch (this) {
      case ComplaintStatus.pending:
        return MyColors.warningLight;
      case ComplaintStatus.inReview:
        return MyColors.blue.withValues(alpha: 0.12);
      case ComplaintStatus.escalated:
        return MyColors.accentLight;
      case ComplaintStatus.resolved:
        return MyColors.successLight;
      case ComplaintStatus.closed:
        return MyColors.surfaceAlt;
    }
  }
}
