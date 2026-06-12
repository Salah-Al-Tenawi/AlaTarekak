part of 'message_cubit.dart';

sealed class MessageState {}

final class MessageInitial extends MessageState {}

final class MessageLoading extends MessageState {}

final class MessageLoaded extends MessageState {
  final List<MessageEntity> messages;
  final bool hasMore;
  MessageLoaded({required this.messages, this.hasMore = true});
}

final class MessageError extends MessageState {
  final String message;
  MessageError(this.message);
}

/// Send/delete failed — the message list is preserved so the chat
/// doesn't disappear; the UI should show a snackbar instead.
final class MessageActionFailed extends MessageState {
  final List<MessageEntity> messages;
  final String error;
  MessageActionFailed({required this.messages, required this.error});
}

final class MessageSending extends MessageState {
  final List<MessageEntity> messages;
  MessageSending(this.messages);
}

final class MessageSent extends MessageState {
  final List<MessageEntity> messages;
  MessageSent(this.messages);
}

final class MessageDeleted extends MessageState {
  final List<MessageEntity> messages;
  MessageDeleted(this.messages);
}
