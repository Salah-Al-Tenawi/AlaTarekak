import 'package:alatarekak/features/support/domain/entity/contact_request_entity.dart';

class ContactRequestModel extends ContactRequestEntity {
  const ContactRequestModel({
    required super.id,
    required super.status,
    required super.createdAt,
  });

  factory ContactRequestModel.fromJson(Map<String, dynamic> json) {
    return ContactRequestModel(
      id: json['id'],
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}
