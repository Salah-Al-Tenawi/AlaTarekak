import 'package:alatarekak/features/support/domain/entity/complaint_status.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';

/// مرفق شكوى — attachments دائماً مصفوفة (قد تكون فارغة)، size_kb عدد عشري
class ComplaintAttachmentEntity {
  final int id;
  final String url;
  final String originalName;
  final String mimeType;
  final double sizeKb;

  const ComplaintAttachmentEntity({
    required this.id,
    required this.url,
    required this.originalName,
    required this.mimeType,
    required this.sizeKb,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';
}

class ComplaintEntity {
  final int id;
  final String title;
  final String description;
  final ComplaintType type;
  final ComplaintStatus status;

  /// رد فريق الدعم — يظهر بعد الحل (يعرض تحت «رد فريق الدعم»)
  final String? resolutionNotes;

  /// اسم الموظف المسؤول — null إن لم يوجد موظف نشط وقت الإرسال
  final String? assignedToName;

  final List<ComplaintAttachmentEntity> attachments;

  /// ISO-8601 — تُنسَّق محلياً بـ intl مع ar، لا تُعرض نصوص السيرفر
  final DateTime? submittedAt;
  final DateTime? resolvedAt;

  const ComplaintEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    this.resolutionNotes,
    this.assignedToName,
    this.attachments = const [],
    this.submittedAt,
    this.resolvedAt,
  });
}
