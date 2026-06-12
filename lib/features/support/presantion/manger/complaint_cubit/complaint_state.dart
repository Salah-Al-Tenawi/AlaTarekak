part of 'complaint_cubit.dart';

abstract class ComplaintState extends Equatable {
  const ComplaintState();
  @override
  List<Object?> get props => [];
}

class ComplaintInitial extends ComplaintState {
  const ComplaintInitial();
}

class ComplaintSubmitting extends ComplaintState {
  const ComplaintSubmitting();
}

class ComplaintSuccess extends ComplaintState {
  final ComplaintEntity complaint;
  const ComplaintSuccess(this.complaint);
  @override
  List<Object?> get props => [complaint.id];
}

class ComplaintFailure extends ComplaintState {
  final String message;
  const ComplaintFailure(this.message);
  @override
  List<Object?> get props => [message];
}
