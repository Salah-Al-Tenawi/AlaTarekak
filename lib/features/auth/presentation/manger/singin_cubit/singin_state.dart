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
  final UserModel user;

  const SinginSuccess({required this.user});
}

final class SinginErorre extends SinginState {
  final String message;

  const SinginErorre(this.message);
}

final class SinginChangeGender extends SinginState {
  final String gender;

  const SinginChangeGender({required this.gender});
}

final class SinginChangeAddress extends SinginState {
  final String address;

  const SinginChangeAddress({required this.address});
}

final class SingInGotoVerfiyOtp extends SinginState {
  final String numberPhone;

  const SingInGotoVerfiyOtp({required this.numberPhone});
}
