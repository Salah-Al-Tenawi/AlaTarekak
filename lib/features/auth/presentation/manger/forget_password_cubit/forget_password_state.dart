part of 'forget_password_cubit.dart';


sealed class ForgetPasswordState extends Equatable {
  const ForgetPasswordState();
  @override
  List<Object> get props => [];
}

final class ForgetPasswordInitial extends ForgetPasswordState {}

final class ForgetPasswordLoading extends ForgetPasswordState {}

final class ForgetPasswordErorr extends ForgetPasswordState {
  final String message;
  const ForgetPasswordErorr({required this.message});
  @override
  List<Object> get props => [message];
}

final class ForgetPasswordSuccsess extends ForgetPasswordState {}

// ━━ انتقل لشاشة OTP ━━
final class ForgetPasswordGoToOtp extends ForgetPasswordState {
  final String email;
  const ForgetPasswordGoToOtp({required this.email});
  @override
  List<Object> get props => [email];
}

// ━━ OTP ━━
final class ForgetPasswordOtpChanged extends ForgetPasswordState {
  final String otp;
  const ForgetPasswordOtpChanged({required this.otp});
  @override
  List<Object> get props => [otp];
}

final class ForgetPasswordOtpTimerTick extends ForgetPasswordState {
  final int secondsLeft;
  final bool canResend;
  const ForgetPasswordOtpTimerTick({
    required this.secondsLeft,
    required this.canResend,
  });
  @override
  List<Object> get props => [secondsLeft, canResend];
}

final class ForgetPasswordOtpVerified extends ForgetPasswordState {
  final String email;
  final String otp;
  const ForgetPasswordOtpVerified({required this.email, required this.otp});
  @override
  List<Object> get props => [email, otp];
}

// ━━ إعادة تعيين كلمة المرور ━━
final class ForgetPasswordResetSuccess extends ForgetPasswordState {}

final class ForgetPasswordPasswordVisible extends ForgetPasswordState {
  final bool isNewVisible;
  final bool isConfirmVisible;
  const ForgetPasswordPasswordVisible({
    required this.isNewVisible,
    required this.isConfirmVisible,
  });
  @override
  List<Object> get props => [isNewVisible, isConfirmVisible];
}