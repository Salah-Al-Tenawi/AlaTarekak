import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';

class CommentModel extends CommentEntity {
  final int id;
  final String comment;
  final Commenter commenter;
  final String created;
  

  CommentModel({
    required this.id,
    required this.comment,
    required this.commenter,
    required this.created,
  }) : super(iduser: commenter.id, text: comment, authorName: commenter.name ,createdAt:created ,authorPhoto:commenter.profilePhoto );

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json[ApiKey.id] ?? 0,
      comment: json[ApiKey.comment] ?? '',
      commenter: Commenter.fromJson(json[ApiKey.commenter] ?? {}),
      created: json[ApiKey.createdAt] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.comment: comment,
      ApiKey.commenter: commenter.toJson(),
      ApiKey.createdAt: createdAt,
    };
  }
}

class Commenter {
  final int id;
  final String name;
  final String? profilePhoto;

  Commenter({
    required this.id,
    required this.name,
    this.profilePhoto,
  });

  factory Commenter.fromJson(Map<String, dynamic> json) {
    return Commenter(
      id: json[ApiKey.id] ?? 0,
      name: json[ApiKey.name] ?? '',
      profilePhoto: json[ApiKey.profilePhoto],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.name: name,
      ApiKey.profilePhoto: profilePhoto,
    };
  }
}