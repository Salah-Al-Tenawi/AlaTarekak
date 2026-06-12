import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

part 'complaint_detail_state.dart';

class ComplaintDetailCubit extends Cubit<ComplaintDetailState> {
  final SupportRepo _repo;

  ComplaintDetailCubit(this._repo) : super(const ComplaintDetailInitial());

  Future<void> loadComplaint(int id) async {
    emit(const ComplaintDetailLoading());
    final result = await _repo.getComplaint(id);
    if (isClosed) return;

    result.fold(
      (failure) {
        // شكوى الغير ترجع 404 (وليس 403) بالتصميم ← نعامله كغير موجودة
        if (failure.message.toLowerCase().contains('not found')) {
          emit(const ComplaintDetailNotFound());
        } else {
          emit(ComplaintDetailFailure(HandelErorrMessage.errServer));
        }
      },
      (complaint) => emit(ComplaintDetailLoaded(complaint)),
    );
  }
}
