import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_type.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

part 'complaint_state.dart';

class ComplaintCubit extends Cubit<ComplaintState> {
  final SupportRepo _repo;

  ComplaintCubit(this._repo) : super(const ComplaintInitial());

  Future<void> submitComplaint(
    String description,
    ComplaintType type,
    List<XFile> attachments,
  ) async {
    emit(const ComplaintSubmitting());
    final result = await _repo.submitComplaint(description, type, attachments);
    result.fold(
      (failure) => emit(ComplaintFailure(failure.message)),
      (_) => emit(const ComplaintSuccess()),
    );
  }
}
