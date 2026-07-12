import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/service/push_token_service.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';

part 'login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepoIm authRepoIm;
  LoginCubit(this.authRepoIm) : super(LoginInitial());

  Future<void> login(String email, String password) async {
    emit(LoginLoading());
    final response = await authRepoIm.signInWithEmail(email, password);
    response.fold((error) {
      emit(LoginError(error.message));
    }, (user) {
      // تسجيل توكن FCM لدى الباك إند بعد نجاح الدخول (لا يعطل التدفق إن فشل)
      PushTokenService.instance.registerToken();
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

  void emitgotoSingin() {
    emit(LoginNavigateToSignup());
    emit(LoginInitial());
  }

  void emitGotoForgetPassword() {
    emit(LoginNavigationToForgetPassword());
    emit(LoginInitial());
  }
}
