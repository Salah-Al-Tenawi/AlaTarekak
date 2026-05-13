import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';
import 'package:alatarekak/features/chat/domain/entity/message_entity.dart';

abstract class ChatRepo {
  Future<Either<Filuar, List<ConversationEntity>>> getConversations();

  Future<Either<Filuar, int>> startConversation({
    required int userId,
  });

  Future<Either<Filuar, List<MessageEntity>>> getMessages({
    required int conversationId,
    int page = 1,
  });

  Future<Either<Filuar, MessageEntity>> sendTextMessage({
    required int conversationId,
    required String content,
  });

  Future<Either<Filuar, MessageEntity>> sendImageMessage({
    required int conversationId,
    required File image,
    String? caption,
  });

  Future<Either<Filuar, Unit>> deleteMessage(int messageId);
  Future<Either<Filuar, Unit>> markMessageRead(int messageId);
  Future<Either<Filuar, int>> getUnreadCount(int conversationId);
}
