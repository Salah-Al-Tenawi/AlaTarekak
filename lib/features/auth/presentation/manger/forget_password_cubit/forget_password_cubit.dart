import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';


import 'dart:async';
part 'forget_password_state.dart';


class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  final AuthRepoIm authRepoIm;
  ForgetPasswordCubit(this.authRepoIm) : super(ForgetPasswordInitial());

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Internal State
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  String _currentOtp = '';
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Step 1 — إرسال الإيميل
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  Future<void> sendEmail(String email) async {
    emit(ForgetPasswordLoading());
    // final response = await authRepoIm.forgetPassword(email);
    // response.fold(
    //   (error) => emit(ForgetPasswordErorr(message: error.message)),
    //   (_) => emit(ForgetPasswordGoToOtp(email: email)),
    // );

    // TODO: احذف هذا عند ربط الـ API
    await Future.delayed(const Duration(seconds: 1));
    emit(ForgetPasswordGoToOtp(email: email));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Step 2 — OTP
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  void onOtpChanged(String otp) {
    _currentOtp = otp;
    emit(ForgetPasswordOtpChanged(otp: otp));
  }

  void startOtpTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        emit(const ForgetPasswordOtpTimerTick(
          secondsLeft: 0,
          canResend: true,
        ));
      } else {
        _secondsLeft--;
        emit(ForgetPasswordOtpTimerTick(
          secondsLeft: _secondsLeft,
          canResend: false,
        ));
      }
    });
  }

  Future<void> resendOtp(String email) async {
    emit(ForgetPasswordLoading());
    // await authRepoIm.forgetPassword(email);
    await Future.delayed(const Duration(seconds: 1));
    startOtpTimer();
  }

  Future<void> verifyOtp(String email) async {
    if (_currentOtp.length < 6) return;
    emit(ForgetPasswordLoading());
    // final response = await authRepoIm.verifyOtp(email, _currentOtp);
    // response.fold(
    //   (error) => emit(ForgetPasswordErorr(message: error.message)),
    //   (_) => emit(ForgetPasswordOtpVerified(email: email, otp: _currentOtp)),
    // );
    await Future.delayed(const Duration(seconds: 1));
    emit(ForgetPasswordOtpVerified(email: email, otp: _currentOtp));
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━
  // Step 3 — إعادة تعيين
  // ━━━━━━━━━━━━━━━━━━━━━━━━
  void toggleNewPassword() {
    _isNewVisible = !_isNewVisible;
    emit(ForgetPasswordPasswordVisible(
      isNewVisible: _isNewVisible,
      isConfirmVisible: _isConfirmVisible,
    ));
  }

  void toggleConfirmPassword() {
    _isConfirmVisible = !_isConfirmVisible;
    emit(ForgetPasswordPasswordVisible(
      isNewVisible: _isNewVisible,
      isConfirmVisible: _isConfirmVisible,
    ));
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    emit(ForgetPasswordLoading());
    // final response = await authRepoIm.resetPassword(email, otp, newPassword);
    // response.fold(
    //   (error) => emit(ForgetPasswordErorr(message: error.message)),
    //   (_) => emit(ForgetPasswordResetSuccess()),
    // );
    await Future.delayed(const Duration(seconds: 1));
    emit(ForgetPasswordResetSuccess());
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
