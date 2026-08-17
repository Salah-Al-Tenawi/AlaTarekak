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

  @override
  List<Object> get props => [message];
}

/// بيانات الدخول صحيحة لكن البريد غير مؤكَّد بعد.
///
/// ليست حالة فشل: الحساب قائم وينقصه رمز التحقق وحده، فتنقله الواجهة
/// إلى شاشة إدخال الرمز بدل عرض خطأ يقف عنده.
class LoginEmailNotVerified extends LoginState {
  final String email;

  const LoginEmailNotVerified(this.email);

  @override
  List<Object> get props => [email];
}

class LoginNavigateToSignup extends LoginState {}

class LoginNavigationToForgetPassword extends LoginState {}
