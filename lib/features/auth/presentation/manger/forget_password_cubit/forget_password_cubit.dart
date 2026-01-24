import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';

part 'forget_password_state.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  final AuthRepoIm authRepoIm;

  ForgetPasswordCubit(this.authRepoIm) : super(ForgetPasswordInitial());

  sendEmail(String email) async {
    // emit(ForgetPasswordLoading());
    // final response = await authRepoIm.forgetPassword(email);
    // response.fold((error) {
    //   emit(ForgetPasswordErorr(message: error.message));
    // }, (dynamic) {
    //   emit(ForgetPasswordSuccsess());
    // });
  }
}
