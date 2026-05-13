import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/features/chat/data/model/message_model.dart';
import 'package:alatarekak/features/chat/domain/entity/message_entity.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';

part 'message_state.dart';

class MessageCubit extends Cubit<MessageState> {
  final ChatRepo chatRepo;
  final int conversationId;

  final List<MessageEntity> _messages = [];
  int _currentPage = 1;
  String? _socketListenerId;

  MessageCubit({required this.chatRepo, required this.conversationId})
      : super(MessageInitial());

  Future<void> loadMessages() async {
    emit(MessageLoading());
    _currentPage = 1;
    _messages.clear();
    final result = await chatRepo.getMessages(
      conversationId: conversationId,
      page: _currentPage,
    );
    result.fold(
      (error) => emit(MessageError(error.message)),
      (msgs) {
        _messages.addAll(msgs);
        emit(MessageLoaded(
            messages: List.from(_messages), hasMore: msgs.isNotEmpty));
        // Clear nav-bar badge for this conversation
        ChatSocketService.instance.resetUnread(conversationId);
        _subscribeToSocket();
        _markLastMessageRead(msgs);
      },
    );
  }

  void _subscribeToSocket() {
    ChatSocketService.instance
        .addMessageListener(conversationId, _onSocketMessage)
        .then((id) => _socketListenerId = id);
  }

  void _onSocketMessage(Map<String, dynamic> data) {
    try {
      final incoming = MessageModel.fromJson(data);
      if (!_messages.any((m) => m.id == incoming.id)) {
        _messages.add(incoming);
        emit(MessageSent(List.from(_messages)));
        // User is reading — mark as read and clear badge immediately
        chatRepo.markMessageRead(incoming.id);
        ChatSocketService.instance.resetUnread(conversationId);
      }
    } catch (_) {}
  }

  void _markLastMessageRead(List msgs) {
    if (msgs.isEmpty) return;
    final lastId = msgs.last.id;
    if (lastId > 0) chatRepo.markMessageRead(lastId);
  }

  Future<void> loadMore() async {
    if (state is! MessageLoaded) return;
    _currentPage++;
    final result = await chatRepo.getMessages(
      conversationId: conversationId,
      page: _currentPage,
    );
    result.fold(
      (error) => emit(MessageError(error.message)),
      (msgs) {
        _messages.insertAll(0, msgs);
        emit(MessageLoaded(
            messages: List.from(_messages), hasMore: msgs.isNotEmpty));
      },
    );
  }

  Future<void> sendText(String content) async {
    if (content.trim().isEmpty) return;
    emit(MessageSending(List.from(_messages)));
    final result = await chatRepo.sendTextMessage(
      conversationId: conversationId,
      content: content.trim(),
    );
    result.fold(
      (error) => emit(MessageError(error.message)),
      (msg) {
        _messages.add(msg);
        emit(MessageSent(List.from(_messages)));
      },
    );
  }

  Future<void> sendImage(File image, {String? caption}) async {
    emit(MessageSending(List.from(_messages)));
    final result = await chatRepo.sendImageMessage(
      conversationId: conversationId,
      image: image,
      caption: caption,
    );
    result.fold(
      (error) => emit(MessageError(error.message)),
      (msg) {
        _messages.add(msg);
        emit(MessageSent(List.from(_messages)));
      },
    );
  }

  Future<void> deleteMessage(int messageId) async {
    final result = await chatRepo.deleteMessage(messageId);
    result.fold(
      (error) => emit(MessageError(error.message)),
      (_) {
        _messages.removeWhere((m) => m.id == messageId);
        emit(MessageDeleted(List.from(_messages)));
      },
    );
  }

  @override
  Future<void> close() async {
    if (_socketListenerId != null) {
      ChatSocketService.instance
          .removeMessageListener(conversationId, _socketListenerId!);
    }
    return super.close();
  }
}
