import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

part 'complaint_list_state.dart';

class ComplaintListCubit extends Cubit<ComplaintListState> {
  final SupportRepo _repo;

  ComplaintListCubit(this._repo) : super(const ComplaintListInitial());

  Future<void> loadComplaints() async {
    emit(const ComplaintListLoading());
    final result = await _repo.getComplaints();
    result.fold(
      (failure) => emit(ComplaintListFailure(failure.message)),
      (list) => emit(ComplaintListLoaded(list)),
    );
  }
}
