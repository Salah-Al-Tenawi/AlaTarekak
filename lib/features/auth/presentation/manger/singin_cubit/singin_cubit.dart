import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'dart:async';

part 'singin_state.dart';


class SinginCubit extends Cubit<SinginState> {
  String gender = "M";
  String? address;
  final AuthRepoIm authRepoIm;

  // ━━ OTP ━━
  String _currentOtp = '';
  int _secondsLeft = 60;
  Timer? _timer;

  SinginCubit(this.authRepoIm) : super(SinginInitial());

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // OTP Methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  void onOtpChanged(String otp) {
    _currentOtp = otp;
    emit(SinginOtpChanged(otp: otp));
  }

  void startOtpTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        emit(const SinginOtpTimerTick(secondsLeft: 0, canResend: true));
      } else {
        _secondsLeft--;
        emit(SinginOtpTimerTick(
          secondsLeft: _secondsLeft,
          canResend: false,
        ));
      }
    });
  }

  void sendOtpAgain() {
    startOtpTimer();
    // todo: call API
  }

  Future<void> checkOtp(String email) async {
  if (_currentOtp.length < 6) return;

  emit(SinginLoading());

  final response = await authRepoIm.verifySinginOtp(email, _currentOtp);

  response.fold(
    (e) {
      emit(SinginErorre(e.message));
    },
    (auth) {
      emit(SinginSuccess(authModel: auth));
    },
  );
}

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // باقي الـ methods
  // ━━━━━━━━━━━━━━━━━━━━━━━━

  void emitChangeGender(String gender) {
    this.gender = gender;
    emit(SinginChangeGender(gender: gender));
  }

  void changAddress(String address) {
    this.address = address;
    emit(SinginChangeAddress(address: address));
  }

  Future signIn(
  String firstName,
  String lastName,
  String gender,
  String email,
  String address,
  String password,
  String verifyPassword,
) async {
  emit(SinginLoading());

  final params = SignUpParams(
    firstName: firstName,
    lastName: lastName,
    gender: gender,
    email: email,
    address: address,
    password: password,
    confirmPassword: verifyPassword,
  );

  final response = await authRepoIm.signIn(params);

  response.fold(
    (failure) {
      emit(SinginErorre(failure.message));
    },
    (succ) {
      emit(SingInGotoVerfiyOtp(email: email));
    },
  );
}

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}