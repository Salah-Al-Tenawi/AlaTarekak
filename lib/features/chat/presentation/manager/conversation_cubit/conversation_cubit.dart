import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/service/chat_socket_service.dart';
import 'package:alatarekak/features/chat/domain/entity/conversation_entity.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';

part 'conversation_state.dart';

class ConversationCubit extends Cubit<ConversationState> {
  final ChatRepo chatRepo;

  // conversationId → listenerId (for cleanup)
  final Map<int, String> _listenerIds = {};

  ConversationCubit({required this.chatRepo}) : super(ConversationInitial());

  Future<void> loadConversations() async {
    emit(ConversationLoading());
    final result = await chatRepo.getConversations();
    result.fold(
      (error) => emit(ConversationError(error.message)),
      (conversations) {
        emit(ConversationLoaded(conversations));
        _subscribeToConversations(conversations);
      },
    );
  }

  void _subscribeToConversations(List<ConversationEntity> conversations) {
    for (final conv in conversations) {
      if (_listenerIds.containsKey(conv.id)) continue;
      ChatSocketService.instance
          .addMessageListener(conv.id, (_) => _refreshSilently())
          .then((id) => _listenerIds[conv.id] = id);
    }
  }

  Future<void> _refreshSilently() async {
    final result = await chatRepo.getConversations();
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
    result.fold(
      (error) => emit(ConversationError(error.message)),
      (conversationId) => emit(ConversationStarted(conversationId)),
    );
  }

  @override
  Future<void> close() async {
    for (final entry in _listenerIds.entries) {
      ChatSocketService.instance.removeMessageListener(entry.key, entry.value);
    }
    return super.close();
  }
}
