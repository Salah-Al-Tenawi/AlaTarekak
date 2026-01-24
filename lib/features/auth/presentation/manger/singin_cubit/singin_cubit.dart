import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';

part 'singin_state.dart';

class SinginCubit extends Cubit<SinginState> {
  String gender = "M";
  String? address;
  final AuthRepoIm authRepoIm;
  SinginCubit(this.authRepoIm) : super(SinginInitial());

  Future singin(String firstName, String lastName, String gender, String email,
      String address, String password, String verifyPassword) async {
    emit(SinginLoading());
    final response = await authRepoIm.singin(
        firstName, lastName, gender, email, address, password, verifyPassword);
    response.fold((filuar) {
      emit(SinginErorre(filuar.message));
    }, (userModel) {
      emit(SinginSuccess(user: userModel));
    });
  }

  void emitChangeGender(String gender) {
    emit(SinginInitial());
    this.gender = gender;
    emit(SinginChangeGender(gender: gender));
  }

  void changAddress(String address) {
    emit(SinginInitial());
    this.address = address;
    emit(SinginChangeAddress(address: address));
  }
//  todo
  checkOTp(String numberPhone, String otp) {
    emit(SinginLoading());
    emit(SinginErorre("لسا ما عملت التابع بالcubit و الapi "));

  } 


  sendOtpAgain(){}
}
