import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/features/support/domain/entity/complaint_entity.dart';
import 'package:alatarekak/features/support/domain/repo/support_repo.dart';

part 'complaint_list_state.dart';

class ComplaintListCubit extends Cubit<ComplaintListState> {
  final SupportRepo _repo;

  ComplaintListCubit(this._repo) : super(const ComplaintListInitial());

  /// الكاش يُعرض فوراً (إن وجد) ثم تُحدَّث القائمة من الشبكة
  Future<void> loadComplaints() async {
    final cached = _repo.getCachedComplaints();
    if (cached != null && cached.isNotEmpty) {
      emit(ComplaintListLoaded(cached));
    } else {
      emit(const ComplaintListLoading());
    }

    final result = await _repo.getComplaints();
    if (isClosed) return;

    result.fold(
      // فشل التحميل بلا كاش — رسالة مع زر إعادة محاولة في الواجهة.
      // (مع وجود كاش، الـ repo يرجعه بدل الفشل فلا نصل هنا)
      (failure) => emit(const ComplaintListFailure(
          'تعذر تحميل الشكاوى، حاول مجدداً')),
      (list) => emit(ComplaintListLoaded(list)),
    );
  }
}
