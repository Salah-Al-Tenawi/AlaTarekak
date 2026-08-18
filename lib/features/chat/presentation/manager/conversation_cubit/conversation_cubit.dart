import 'dart:async';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'conversation_state.dart';

class ConversationCubit extends SafeCubit<ConversationState> {
  final ChatRepo chatRepo;

  // conversationId → listenerId (for cleanup)
  final Map<int, String> _listenerIds = {};
  StreamSubscription<void>? _reconnectSub;

  ConversationCubit({required this.chatRepo}) : super(ConversationInitial()) {
    // Refresh after a socket drop — messages received while offline never
    // reached us, so the list and unread counts may be stale.
    _reconnectSub = ChatSocketService.instance.reconnectStream
        .listen((_) => _refreshSilently());
  }

  Future<void> loadConversations() async {
    emit(ConversationLoading());
    final result = await chatRepo.getConversations();
    if (isClosed) return;
    result.fold(
      (error) => emit(ConversationError(HandelErorrMessage.chat(error.message))),
      (conversations) {
        emit(ConversationLoaded(conversations));
        _subscribeToConversations(conversations);
      },
    );
  }

  void _subscribeToConversations(List<ConversationEntity> conversations) {
    for (final conv in conversations) {
      if (_listenerIds.containsKey(conv.id)) continue;
      // Reserve the slot synchronously so a second pass doesn't double-subscribe
      // while the first subscription is still in flight.
      _listenerIds[conv.id] = '';
      ChatSocketService.instance
          .addMessageListener(conv.id, (_) => _refreshSilently())
          .then((id) {
        if (isClosed) {
          ChatSocketService.instance.removeMessageListener(conv.id, id);
        } else {
          _listenerIds[conv.id] = id;
        }
      }).catchError((_) {
        _listenerIds.remove(conv.id);
      });
    }
  }

  Future<void> _refreshSilently() async {
    final result = await chatRepo.getConversations();
    if (isClosed) return;
    result.fold(
      (_) {},
      (conversations) {
        emit(ConversationLoaded(conversations));
        // Subscribe to any new conversations that appeared
        _subscribeToConversations(conversations);
      },
    );
  }

  Future<void> startConversation({required int userId}) async {
    emit(ConversationLoading());
    final result = await chatRepo.startConversation(userId: userId);
    if (isClosed) return;
    result.fold(
      (error) => emit(ConversationError(HandelErorrMessage.chat(error.message))),
      (conversationId) => emit(ConversationStarted(conversationId)),
    );
  }

  @override
  Future<void> close() async {
    _reconnectSub?.cancel();
    for (final entry in _listenerIds.entries) {
      if (entry.value.isEmpty) continue;
      ChatSocketService.instance.removeMessageListener(entry.key, entry.value);
    }
    return super.close();
  }
}
