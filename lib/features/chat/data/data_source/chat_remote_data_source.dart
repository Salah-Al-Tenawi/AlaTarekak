import 'dart:io';
import 'package:dio/dio.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/features/chat/data/model/conversation_model.dart';
import 'package:alatarekak/features/chat/data/model/message_model.dart';

abstract class ChatRemoteDataSource {
  final DioConSumer api;
  ChatRemoteDataSource({required this.api});

  Future<List<ConversationModel>> getConversations();
  Future<int> startConversation({required int userId});
  Future<List<MessageModel>> getMessages({
    required int conversationId,
    int page = 1,
  });
  Future<MessageModel> sendTextMessage({
    required int conversationId,
    required String content,
  });
  Future<MessageModel> sendImageMessage({
    required int conversationId,
    required File image,
    String? caption,
  });
  Future<void> deleteMessage(int messageId);
  Future<void> markMessageRead(int messageId);
  Future<int> getUnreadCount(int conversationId);
}

class ChatRemoteDataSourceImpl extends ChatRemoteDataSource {
  ChatRemoteDataSourceImpl({required super.api});

  @override
  Future<List<ConversationModel>> getConversations() async {
    final response = await api.get(ApiEndPoint.conversation);
    final List data = _extractList(response);
    return data
        .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> startConversation({required int userId}) async {
    final response = await api.post(
      ApiEndPoint.conversation,
      data: {ApiKey.userId: userId},
    );
    // Response: { "success": true, "data": { "conversation_id": 3 } }
    final data = _extractData(response);
    return data['conversation_id'] as int? ?? 0;
  }

  @override
  Future<List<MessageModel>> getMessages({
    required int conversationId,
    int page = 1,
  }) async {
    final response = await api.get(
      '${ApiEndPoint.conversation}/$conversationId/messages',
      queryParameters: {'page': page},
    );
    final List data = _extractList(response);
    return data
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MessageModel> sendTextMessage({
    required int conversationId,
    required String content,
  }) async {
    final response = await api.post(
      '${ApiEndPoint.conversation}/$conversationId/messages',
      data: {ApiKey.type: 'text', ApiKey.content: content},
    );
    return MessageModel.fromJson(_extractData(response));
  }

  @override
  Future<MessageModel> sendImageMessage({
    required int conversationId,
    required File image,
    String? caption,
  }) async {
    final multipart = await MultipartFile.fromFile(
      image.path,
      filename: image.path.split('/').last,
    );
    final response = await api.post(
      '${ApiEndPoint.conversation}/$conversationId/messages',
      isFomrData: true,
      data: {
        ApiKey.type: 'image',
        ApiKey.image: multipart,
        if (caption != null) ApiKey.caption: caption,
      },
    );
    return MessageModel.fromJson(_extractData(response));
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await api.delete('${ApiEndPoint.deletmessage}/$messageId');
  }

  @override
  Future<void> markMessageRead(int messageId) async {
    await api.post('${ApiEndPoint.markMessageRead}/$messageId/read');
  }

  @override
  Future<int> getUnreadCount(int conversationId) async {
    final response = await api.get(
      '${ApiEndPoint.conversationUnreadCount}/$conversationId/unread-count',
    );
    if (response is Map) {
      return response['unread_count'] as int? ?? 0;
    }
    return 0;
  }

  List _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map) {
      for (final key in ['data', 'conversations', 'messages']) {
        if (response[key] is List) return response[key] as List;
      }
    }
    return [];
  }

  Map<String, dynamic> _extractData(dynamic response) {
    if (response is Map<String, dynamic>) {
      for (final key in ['data', 'conversation', 'message']) {
        if (response[key] is Map) return response[key] as Map<String, dynamic>;
      }
      return response;
    }
    return {};
  }
}
