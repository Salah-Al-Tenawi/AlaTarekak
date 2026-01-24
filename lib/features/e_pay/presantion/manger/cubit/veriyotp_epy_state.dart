part of 'veriyotp_epy_cubit.dart';

sealed class VeriyotpEpyState extends Equatable {
  const VeriyotpEpyState();

  @override
  List<Object> get props => [];
}

final class VeriyotpEpyInitial extends VeriyotpEpyState {}

final class VeriyotpEpyLoading extends VeriyotpEpyState {}

final class VeriyotpEpyErorr extends VeriyotpEpyState {
  final String message;

  const VeriyotpEpyErorr({required this.message});
}

final class VeriyotpEpySuccInit extends VeriyotpEpyState {}

final class VeriyotpEpySuccCreate extends VeriyotpEpyState {}
