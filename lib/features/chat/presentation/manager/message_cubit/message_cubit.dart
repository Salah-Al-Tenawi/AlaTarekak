import 'dart:async';
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

  // Backend returns 50 messages per page with no pagination metadata —
  // fewer than 50 means the last page.
  static const _pageSize = 50;

  final List<MessageEntity> _messages = [];
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _socketListenerId;
  StreamSubscription<void>? _reconnectSub;

  MessageCubit({required this.chatRepo, required this.conversationId})
      : super(MessageInitial());

  Future<void> loadMessages() async {
    emit(MessageLoading());
    _currentPage = 1;
    _hasMore = true;
    _messages.clear();
    final result = await chatRepo.getMessages(
      conversationId: conversationId,
      page: _currentPage,
    );
    if (isClosed) return;
    result.fold(
      (error) => emit(MessageError(error.message)),
      (msgs) {
        _messages.addAll(msgs);
        _hasMore = msgs.length >= _pageSize;
        emit(MessageLoaded(messages: List.from(_messages), hasMore: _hasMore));
        // Clear nav-bar badge for this conversation
        ChatSocketService.instance.resetUnread(conversationId);
        _subscribeToSocket();
      },
    );
  }

  void _subscribeToSocket() {
    if (_socketListenerId == null) {
      ChatSocketService.instance
          .addMessageListener(conversationId, _onSocketMessage)
          .then((id) {
        // The cubit may have been closed while subscribing.
        if (isClosed) {
          ChatSocketService.instance.removeMessageListener(conversationId, id);
        } else {
          _socketListenerId = id;
        }
      }).catchError((_) {});
    }
    // Events missed while offline are lost — refetch when the socket is back.
    _reconnectSub ??=
        ChatSocketService.instance.reconnectStream.listen((_) => _resync());
  }

  void _onSocketMessage(Map<String, dynamic> data) {
    try {
      final incoming = MessageModel.fromJson(data);
      // User is inside this conversation — its badge must stay cleared,
      // even when the message is a duplicate or our own echo.
      ChatSocketService.instance.resetUnread(conversationId);
      if (_messages.any((m) => m.id == incoming.id)) return;
      _messages.add(incoming);
      emit(MessageSent(List.from(_messages)));
    } catch (_) {}
  }

  /// Fetches the latest page and appends any messages that arrived while
  /// the socket was disconnected.
  Future<void> _resync() async {
    final result = await chatRepo.getMessages(
      conversationId: conversationId,
      page: 1,
    );
    if (isClosed) return;
    result.fold(
      (_) {},
      (msgs) {
        final missed =
            msgs.where((m) => !_messages.any((e) => e.id == m.id)).toList();
        if (missed.isEmpty) return;
        _messages.addAll(missed);
        emit(MessageSent(List.from(_messages)));
        ChatSocketService.instance.resetUnread(conversationId);
      },
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _messages.isEmpty) return;
    _isLoadingMore = true;
    final result = await chatRepo.getMessages(
      conversationId: conversationId,
      page: _currentPage + 1,
    );
    if (isClosed) return;
    result.fold(
      // Keep the current list; scrolling up again retries the same page.
      (_) {},
      (msgs) {
        _currentPage++;
        _hasMore = msgs.length >= _pageSize;
        final older =
            msgs.where((m) => !_messages.any((e) => e.id == m.id)).toList();
        _messages.insertAll(0, older);
        emit(MessageLoaded(messages: List.from(_messages), hasMore: _hasMore));
      },
    );
    _isLoadingMore = false;
  }

  Future<void> sendText(String content) async {
    if (content.trim().isEmpty) return;
    emit(MessageSending(List.from(_messages)));
    final result = await chatRepo.sendTextMessage(
      conversationId: conversationId,
      content: content.trim(),
    );
    if (isClosed) return;
    result.fold(
      // Send failures come back as HTTP 500 with a technical English
      // message — show a readable one instead.
      (error) => emit(MessageActionFailed(
          messages: List.from(_messages),
          error: 'فشل إرسال الرسالة، تحقق من الاتصال وحاول مجدداً')),
      (msg) {
        // The socket echo may have already added this message.
        if (!_messages.any((m) => m.id == msg.id)) _messages.add(msg);
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
    if (isClosed) return;
    result.fold(
      (error) => emit(MessageActionFailed(
          messages: List.from(_messages),
          error: 'فشل إرسال الصورة، تحقق من الاتصال وحاول مجدداً')),
      (msg) {
        if (!_messages.any((m) => m.id == msg.id)) _messages.add(msg);
        emit(MessageSent(List.from(_messages)));
      },
    );
  }

  Future<void> deleteMessage(int messageId) async {
    final result = await chatRepo.deleteMessage(messageId);
    if (isClosed) return;
    result.fold(
      (error) => emit(MessageActionFailed(
          messages: List.from(_messages),
          error: 'فشل حذف الرسالة، حاول مجدداً')),
      (_) {
        _messages.removeWhere((m) => m.id == messageId);
        emit(MessageDeleted(List.from(_messages)));
      },
    );
  }

  @override
  Future<void> close() async {
    _reconnectSub?.cancel();
    if (_socketListenerId != null) {
      ChatSocketService.instance
          .removeMessageListener(conversationId, _socketListenerId!);
    }
    return super.close();
  }
}
