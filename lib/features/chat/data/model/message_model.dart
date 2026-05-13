import 'package:alatarekak/features/chat/domain/entity/message_entity.dart';

class MessageSenderModel extends MessageSenderEntity {
  const MessageSenderModel({
    required super.id,
    required super.name,
    super.avatar,
  });

  factory MessageSenderModel.fromJson(Map<String, dynamic> json) {
    return MessageSenderModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: (json['profile_photo'] ?? json['avatar']) as String?,
    );
  }
}

class MessageModel extends MessageEntity {
  const MessageModel({
    required super.id,
    required super.conversationId,
    required super.sender,
    required super.content,
    required super.type,
    super.image,
    super.caption,
    required super.isEdited,
    required super.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final senderJson = json['sender'] as Map<String, dynamic>? ?? {};
    final type = json['type'] as String? ?? 'text';
    final content = json['content'] as String? ?? '';

    return MessageModel(
      id: json['id'] as int? ?? 0,
      conversationId: json['conversation_id'] as int? ?? 0,
      sender: MessageSenderModel.fromJson(senderJson),
      content: content,
      type: type,
      image: type == 'image'
          ? (json['image'] as String? ?? (content.isNotEmpty ? content : null))
          : json['image'] as String?,
      caption: json['caption'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
