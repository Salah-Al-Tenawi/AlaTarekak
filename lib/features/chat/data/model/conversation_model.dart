import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';

class ParticipantModel extends ParticipantEntity {
  const ParticipantModel({
    required super.id,
    required super.name,
    super.avatar,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      avatar: (json['profile_photo'] ?? json['avatar']) as String?,
    );
  }
}

class LastMessageModel extends LastMessageEntity {
  const LastMessageModel({
    required super.content,
    required super.createdAt,
    super.type,
  });

  factory LastMessageModel.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String? ?? 'text';
    return LastMessageModel(
      content: json['content'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      type: type,
    );
  }
}

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.type,
    required super.title,
    required super.otherParticipant,
    super.lastMessage,
    required super.updatedAt,
    super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final participantJson =
        json['other_participant'] as Map<String, dynamic>? ?? {};
    final lastMsgJson = json['last_message'] as Map<String, dynamic>?;

    return ConversationModel(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'direct',
      title: json['title'] as String? ?? '',
      otherParticipant: ParticipantModel.fromJson(participantJson),
      lastMessage:
          lastMsgJson != null ? LastMessageModel.fromJson(lastMsgJson) : null,
      updatedAt: json['updated_at'] as String? ?? '',
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }
}
