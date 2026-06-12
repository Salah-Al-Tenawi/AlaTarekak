part of 'complaint_detail_cubit.dart';

abstract class ComplaintDetailState extends Equatable {
  const ComplaintDetailState();
  @override
  List<Object?> get props => [];
}

class ComplaintDetailInitial extends ComplaintDetailState {
  const ComplaintDetailInitial();
}

class ComplaintDetailLoading extends ComplaintDetailState {
  const ComplaintDetailLoading();
}

class ComplaintDetailLoaded extends ComplaintDetailState {
  final ComplaintEntity complaint;
  const ComplaintDetailLoaded(this.complaint);
  @override
  List<Object?> get props => [complaint.id, complaint.status];
}

/// 404 — الشكوى غير موجودة أو تخص مستخدماً آخر ← ارجع للقائمة
class ComplaintDetailNotFound extends ComplaintDetailState {
  const ComplaintDetailNotFound();
}

class ComplaintDetailFailure extends ComplaintDetailState {
  final String message;
  const ComplaintDetailFailure(this.message);
  @override
  List<Object?> get props => [message];
}
