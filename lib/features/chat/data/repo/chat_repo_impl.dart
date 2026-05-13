import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/chat/data/data_source/chat_remote_data_source.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';
import 'package:alatarekak/features/chat/domain/entity/message_entity.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';

class ChatRepoImpl extends ChatRepo {
  final ChatRemoteDataSource remoteDataSource;
  ChatRepoImpl({required this.remoteDataSource});

  @override
  Future<Either<Filuar, List<ConversationEntity>>> getConversations() async {
    try {
      return right(await remoteDataSource.getConversations());
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, int>> startConversation({required int userId}) async {
    try {
      return right(await remoteDataSource.startConversation(userId: userId));
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, List<MessageEntity>>> getMessages({
    required int conversationId,
    int page = 1,
  }) async {
    try {
      return right(await remoteDataSource.getMessages(
        conversationId: conversationId,
        page: page,
      ));
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, MessageEntity>> sendTextMessage({
    required int conversationId,
    required String content,
  }) async {
    try {
      return right(await remoteDataSource.sendTextMessage(
        conversationId: conversationId,
        content: content,
      ));
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, MessageEntity>> sendImageMessage({
    required int conversationId,
    required File image,
    String? caption,
  }) async {
    try {
      return right(await remoteDataSource.sendImageMessage(
        conversationId: conversationId,
        image: image,
        caption: caption,
      ));
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, Unit>> deleteMessage(int messageId) async {
    try {
      await remoteDataSource.deleteMessage(messageId);
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, Unit>> markMessageRead(int messageId) async {
    try {
      await remoteDataSource.markMessageRead(messageId);
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, int>> getUnreadCount(int conversationId) async {
    try {
      final count = await remoteDataSource.getUnreadCount(conversationId);
      return right(count);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
