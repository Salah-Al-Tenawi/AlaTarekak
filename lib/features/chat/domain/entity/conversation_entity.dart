class ParticipantEntity {
  final int id;
  final String name;
  final String? avatar;

  const ParticipantEntity({
    required this.id,
    required this.name,
    this.avatar,
  });
}

class LastMessageEntity {
  final String content;
  final String createdAt;
  final String type;

  const LastMessageEntity({
    required this.content,
    required this.createdAt,
    this.type = 'text',
  });

  bool get isImage => type == 'image' || content.contains('/storage/');
}

class ConversationEntity {
  final int id;
  final String type;
  final String title;
  final ParticipantEntity otherParticipant;
  final LastMessageEntity? lastMessage;
  final String updatedAt;
  final int unreadCount;

  const ConversationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.otherParticipant,
    this.lastMessage,
    required this.updatedAt,
    this.unreadCount = 0,
  });
}
