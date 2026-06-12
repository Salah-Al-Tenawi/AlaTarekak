import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/data/repo/e_pay_repo_im.dart';

part 'wallet_state.dart';

class WalletCubit extends Cubit<WalletState> {
  final EPayRepoIm _repo;
  WalletCubit(this._repo) : super(WalletInitial());

  Future<void> getBalance() async {
    emit(WalletLoading());
    final response = await _repo.getBalance();
    response.fold((erorr) {
      // "Wallet not found" ليس خطأً فعلياً — المستخدم لم يفعّل محفظته بعد.
      if (erorr.message.toLowerCase().contains('wallet not found')) {
        emit(WalletNotActivated());
      } else {
        emit(WalletErorr(
            message: HandelErorrMessage.checkbalance(erorr.message)));
      }
    }, (balance) {
      emit(WalletLoaded(balance: balance));
    });
  }
}
