import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_status.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';

class ComplaintAttachmentModel extends ComplaintAttachmentEntity {
  const ComplaintAttachmentModel({
    required super.id,
    required super.url,
    required super.originalName,
    required super.mimeType,
    required super.sizeKb,
  });

  factory ComplaintAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ComplaintAttachmentModel(
      id: json['id'] as int,
      url: json['url']?.toString() ?? '',
      originalName: json['original_name']?.toString() ?? '',
      mimeType: json['mime_type']?.toString() ?? '',
      sizeKb: (json['size_kb'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'original_name': originalName,
        'mime_type': mimeType,
        'size_kb': sizeKb,
      };

  factory ComplaintAttachmentModel.fromEntity(
          ComplaintAttachmentEntity e) =>
      ComplaintAttachmentModel(
        id: e.id,
        url: e.url,
        originalName: e.originalName,
        mimeType: e.mimeType,
        sizeKb: e.sizeKb,
      );
}

class ComplaintModel extends ComplaintEntity {
  const ComplaintModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    required super.status,
    super.resolutionNotes,
    super.assignedToName,
    super.attachments,
    super.submittedAt,
    super.resolvedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'] as List? ?? [];
    final assignedTo = json['assigned_to'];

    return ComplaintModel(
      id: json['id'] as int,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      // type_label/status_label/status_color تُتجاهل — الخرائط محلية
      type: ComplaintType.fromString(json['type']?.toString()),
      status: ComplaintStatus.fromString(json['status']?.toString()),
      resolutionNotes: json['resolution_notes']?.toString(),
      assignedToName: assignedTo is Map<String, dynamic>
          ? assignedTo['name']?.toString()
          : null,
      attachments: rawAttachments
          .whereType<Map<String, dynamic>>()
          .map(ComplaintAttachmentModel.fromJson)
          .toList(),
      submittedAt:
          DateTime.tryParse(json['submitted_at']?.toString() ?? ''),
      resolvedAt: DateTime.tryParse(json['resolved_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.apiValue,
        'status': status.apiValue,
        'resolution_notes': resolutionNotes,
        'assigned_to':
            assignedToName == null ? null : {'name': assignedToName},
        'attachments': attachments
            .map((a) => ComplaintAttachmentModel.fromEntity(a).toJson())
            .toList(),
        'submitted_at': submittedAt?.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  factory ComplaintModel.fromEntity(ComplaintEntity e) => ComplaintModel(
        id: e.id,
        title: e.title,
        description: e.description,
        type: e.type,
        status: e.status,
        resolutionNotes: e.resolutionNotes,
        assignedToName: e.assignedToName,
        attachments: e.attachments,
        submittedAt: e.submittedAt,
        resolvedAt: e.resolvedAt,
      );
}
