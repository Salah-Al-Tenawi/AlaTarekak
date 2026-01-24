import 'package:alatarekak/features/profiles/data/model/documents_model.dart';
import 'package:alatarekak/features/profiles/domain/entity/car_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';

class ProfileEntity {
  final String fullname;
  final String? profilePhoto;
  final int numberOfides;
  final int totalRating;
  final double averageRating;
  final String verification;
  final String description;  // <-- بدون late
  final String address;
  final String gender;
  final CarEntity? car;
  final List<CommentEntity>? comments;
  final DocumentsModel? documents;

  ProfileEntity({
    required this.fullname,
    required this.profilePhoto,
    required this.numberOfides,
    required this.totalRating,
    required this.averageRating,
    required this.verification,
    required this.description,
    required this.address,
    required this.gender,
    required this.car,
    required this.comments,
    required this.documents,
  });

  ProfileEntity copyWith({
    String? fullname,
    String? profilePhoto,
    int? numberOfides,
    int? totalRating,
    double? averageRating,
    String? verification,
    String? description,
    String? address,
    String? gender,
    CarEntity? car,
    List<CommentEntity>? comments,
    DocumentsModel? documents,
  }) {
    return ProfileEntity(
      fullname: fullname ?? this.fullname,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      numberOfides: numberOfides ?? this.numberOfides,
      totalRating: totalRating ?? this.totalRating,
      averageRating: averageRating ?? this.averageRating,
      verification: verification ?? this.verification,
      description: description ?? this.description,
      address: address ?? this.address,
      gender: gender ?? this.gender,
      car: car ?? this.car,
      comments: comments ?? this.comments,
      documents: documents ?? this.documents,
    );
  }

  // باقي الكود بدون تغيير
}
