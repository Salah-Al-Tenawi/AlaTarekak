part of 'complaint_list_cubit.dart';

abstract class ComplaintListState extends Equatable {
  const ComplaintListState();
  @override
  List<Object> get props => [];
}

class ComplaintListInitial extends ComplaintListState {
  const ComplaintListInitial();
}

class ComplaintListLoading extends ComplaintListState {
  const ComplaintListLoading();
}

class ComplaintListLoaded extends ComplaintListState {
  final List<ComplaintEntity> complaints;
  const ComplaintListLoaded(this.complaints);
  @override
  List<Object> get props => [complaints];
}

class ComplaintListFailure extends ComplaintListState {
  final String message;
  const ComplaintListFailure(this.message);
  @override
  List<Object> get props => [message];
}
