import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/auth/data/repo/auth_repo_im.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/reset_password_params.dart';
import 'dart:async';

part 'forget_password_state.dart';

class ForgetPasswordCubit extends Cubit<ForgetPasswordState> {
  final AuthRepoIm authRepoIm;
  ForgetPasswordCubit(this.authRepoIm) : super(ForgetPasswordInitial());

  String _currentOtp = '';
  int _secondsLeft = 60;
  Timer? _timer;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  bool get isOtpComplete => _currentOtp.length >= 6;

  // ━━ Step 1 — إرسال الإيميل ━━
  Future<void> sendEmail(String email) async {
    emit(ForgetPasswordLoading());
    final response = await authRepoIm.forgotPassword(email);
    response.fold(
      (error) => emit(ForgetPasswordErorr(message: error.message)),
      (_) => emit(ForgetPasswordGoToOtp(email: email)),
    );
  }

  // ━━ Step 2 — OTP ━━
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
        emit(const ForgetPasswordOtpTimerTick(secondsLeft: 0, canResend: true));
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
    final response = await authRepoIm.resendOtpForgetPassword(email);
    response.fold(
      (error) => emit(ForgetPasswordErorr(message: error.message)),
      (_) => startOtpTimer(),
    );
  }

  Future<void> verifyOtp(String email) async {
    if (_currentOtp.length < 6) return;
    _timer?.cancel(); // stop countdown so it doesn't override the loading state
    emit(ForgetPasswordLoading());
    final result = await authRepoIm.verifyOtpResetPassword(email, _currentOtp);
    result.fold(
      (error) => emit(ForgetPasswordErorr(message: error.message)),
      (token) => emit(ForgetPasswordOtpVerified(email: email, resetToken: token)),
    );
  }

  // ━━ Step 3 — إعادة تعيين كلمة المرور ━━
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
    required String resetToken,
    required String newPassword,
  }) async {
    emit(ForgetPasswordLoading());
    final response = await authRepoIm.resetPassword(
      ResetPasswordParams(
        resetToken: resetToken,
        newPassword: newPassword,
        confirmPassword: newPassword,
      ),
    );
    response.fold(
      (error) => emit(ForgetPasswordErorr(message: error.message)),
      (_) => emit(ForgetPasswordResetSuccess()),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
