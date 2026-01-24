part of 'login_cubit.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

class LoginError extends LoginState {
  final String message;

  const LoginError(this.message);
}

class LoginNavigateToSignup extends LoginState {}

class LoginNavigationToForgetPassword extends LoginState {}
