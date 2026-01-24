
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';

part 'veriyotp_epy_state.dart';

class VeriyotpEpyCubit extends Cubit<VeriyotpEpyState> {
  final EPayRepoIm _repo;
  VeriyotpEpyCubit(this._repo) : super(VeriyotpEpyInitial());

  initialWallet(String numberPhone, String password) async {
    emit(VeriyotpEpyLoading());
    final response = await _repo.initWallet(numberPhone, password);
    response.fold((erorr) {
      emit(VeriyotpEpyErorr(message: erorr.message));
    }, (succ) {
      emit(VeriyotpEpySuccInit());
    });
  }


  createWallet(String numberPhone, String otpCode)async{ 
    emit(VeriyotpEpyLoading());
    final response = await _repo.createWallet(numberPhone, otpCode);
    response.fold((erorr) {
      emit(VeriyotpEpyErorr(message: erorr.message));
    }, (succ) {
      emit(VeriyotpEpySuccCreate());
    });
  }
}
