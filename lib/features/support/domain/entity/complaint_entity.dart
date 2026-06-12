import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';

class ComplaintEntity {
  final int id;
  final String description;
  final String status;
  final String createdAt;
  final ComplaintType type;

  const ComplaintEntity({
    required this.id,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.type,
  });
}
