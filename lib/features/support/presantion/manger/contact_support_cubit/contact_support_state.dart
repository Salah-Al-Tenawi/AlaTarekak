part of 'contact_support_cubit.dart';

abstract class ContactSupportState extends Equatable {
  const ContactSupportState();
  @override
  List<Object> get props => [];
}

class ContactSupportInitial extends ContactSupportState {
  const ContactSupportInitial();
}

class ContactSupportRequesting extends ContactSupportState {
  const ContactSupportRequesting();
}

class ContactSupportAgentRequested extends ContactSupportState {
  const ContactSupportAgentRequested();
}

class ContactSupportFailure extends ContactSupportState {
  final String message;
  const ContactSupportFailure(this.message);
  @override
  List<Object> get props => [message];
}
