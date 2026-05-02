part of 'singin_cubit.dart';

sealed class SinginState extends Equatable {
  const SinginState();
  @override
  List<Object> get props => [];
}

final class SinginInitial extends SinginState {
  final String gender = "male";
}

final class SinginLoading extends SinginState {}

final class SinginSuccess extends SinginState {
  final UserModel authModel;
  const SinginSuccess({required this.authModel});
  @override
  List<Object> get props => [authModel];
}

final class SinginErorre extends SinginState {
  final String message;
  const SinginErorre(this.message);
  @override
  List<Object> get props => [message];
}

final class SinginChangeGender extends SinginState {
  final String gender;
  const SinginChangeGender({required this.gender});
  @override
  List<Object> get props => [gender];
}

final class SinginChangeAddress extends SinginState {
  final String address;
  const SinginChangeAddress({required this.address});
  @override
  List<Object> get props => [address];
}

final class SingInGotoVerfiyOtp extends SinginState {
  final String email;
  const SingInGotoVerfiyOtp({required this.email});
  @override
  List<Object> get props => [email];
}

// ━━━━━━━━━━━━━━━━━━━━━━━━
// OTP States
// ━━━━━━━━━━━━━━━━━━━━━━━━

final class SinginOtpChanged extends SinginState {
  final String otp;
  const SinginOtpChanged({required this.otp});
  @override
  List<Object> get props => [otp];
}

final class SinginOtpTimerTick extends SinginState {
  final int secondsLeft;
  final bool canResend;
  const SinginOtpTimerTick({
    required this.secondsLeft,
    required this.canResend,
  });
  @override
  List<Object> get props => [secondsLeft, canResend];
}