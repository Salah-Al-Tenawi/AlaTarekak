class CommentEntity {
  final int iduser;
  final String text;
  final String authorName;
  final String? authorPhoto;
  final String createdAt;

  const CommentEntity({
    required this.iduser,
    required this.text,
    required this.authorName,
    this.authorPhoto,
    required this.createdAt,
  });
}
