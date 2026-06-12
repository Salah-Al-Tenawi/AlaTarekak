import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';

class ComplaintModel extends ComplaintEntity {
  const ComplaintModel({
    required super.id,
    required super.description,
    required super.status,
    required super.createdAt,
    required super.type,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'unread',
      createdAt: json['created_at'] ?? '',
      type: ComplaintType.fromString(json['type'] ?? 'other'),
    );
  }
}
