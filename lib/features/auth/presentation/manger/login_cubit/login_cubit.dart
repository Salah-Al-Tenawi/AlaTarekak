import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepoIm authRepoIm;
  LoginCubit(this.authRepoIm) : super(LoginInitial());

  login(String email, String password) async {
    emit(LoginLoading());
    final response = await authRepoIm.login(email, password);
    response.fold((error) {
      emit(LoginError(error.message));
    }, (user) {
      emit(LoginSuccess());
    });
  }

  // loginWithGoogle() async {
  //   final response = await authRepoIm.singingWithGoogle();
  //   response.fold((erorr) {
  //     print("erorr===================================");

  //     print(erorr.message);
  //     print("erorr===================================");
  //   }, (user) {
  //     print("user===================================");
  //     print(user.firstName);
  //     print(user.lastName);
  //     print(user.address);
  //     print("user===================================");
  //   });
  // }

  emitgotoSingin() {
    emit(LoginNavigateToSignup());
    emit(LoginInitial());
  }

  emitGotoForgetPassword() {
    emit(LoginNavigationToForgetPassword());
    emit(LoginInitial());
  }
}
