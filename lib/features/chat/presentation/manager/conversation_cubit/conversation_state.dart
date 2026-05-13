part of 'conversation_cubit.dart';

sealed class ConversationState {}

final class ConversationInitial extends ConversationState {}

final class ConversationLoading extends ConversationState {}

final class ConversationLoaded extends ConversationState {
  final List<ConversationEntity> conversations;
  final int totalUnread;
  ConversationLoaded(this.conversations)
      : totalUnread =
            conversations.fold(0, (sum, c) => sum + c.unreadCount);
}

final class ConversationError extends ConversationState {
  final String message;
  ConversationError(this.message);
}

final class ConversationStarted extends ConversationState {
  final int conversationId;
  ConversationStarted(this.conversationId);
}
