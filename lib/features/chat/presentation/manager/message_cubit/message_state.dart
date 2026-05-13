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
