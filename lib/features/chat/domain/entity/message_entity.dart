class MessageSenderEntity {
  final int id;
  final String name;
  final String? avatar;

  const MessageSenderEntity({
    required this.id,
    required this.name,
    this.avatar,
  });
}

class MessageEntity {
  final int id;
  final int conversationId;
  final MessageSenderEntity sender;
  final String content;
  final String type; // "text" | "image"
  final String? image;
  final String? caption;
  final bool isEdited;
  final String createdAt;

  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.type,
    this.image,
    this.caption,
    required this.isEdited,
    required this.createdAt,
  });

  bool get isImage => type == 'image';
}
