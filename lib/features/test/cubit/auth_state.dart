part of 'auth_cubit.dart';

sealed class AuthState extends Equatable {
  const AuthState(this.isloading);

  @override
  List<Object> get props => [];

  final bool isloading;
}

final class AuthInitial extends AuthState {
  const AuthInitial(super.isloading);
}

final class LodaingState extends AuthState {
  const LodaingState(super.isloading);
}
