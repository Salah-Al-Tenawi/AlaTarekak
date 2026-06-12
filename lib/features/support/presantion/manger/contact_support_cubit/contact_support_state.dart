part of 'contact_support_cubit.dart';

abstract class ContactSupportState extends Equatable {
  const ContactSupportState();
  @override
  List<Object?> get props => [];
}

class ContactSupportInitial extends ContactSupportState {
  const ContactSupportInitial();
}

class ContactSupportRequesting extends ContactSupportState {
  const ContactSupportRequesting();
}

/// المحادثة جاهزة — انتقل لشاشة الشات بـ conversationId
class ContactSupportReady extends ContactSupportState {
  final int conversationId;
  final String? agentName;

  const ContactSupportReady({
    required this.conversationId,
    this.agentName,
  });

  @override
  List<Object?> get props => [conversationId, agentName];
}

class ContactSupportFailure extends ContactSupportState {
  final String message;
  const ContactSupportFailure(this.message);
  @override
  List<Object?> get props => [message];
}
