part of 'login_cubit.dart';

sealed class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

final class LoginInitial extends LoginState {}

final class LoginLoading extends LoginState {}

class LoginSuccess extends LoginState {}

/// **الرسالة خام إنجليزية** — الواجهة تفحصها قبل أن تعرّبها (تمييز
/// «البريد غير مؤكَّد» مثلاً)، فالتعريب يقع هناك لا هنا. و[statusCode]
/// يرافقها ليُذيَّل به النصّ المعروض — انظر [HandelErorrMessage.withStatus].
class LoginError extends LoginState {
  final String message;
  final int? statusCode;

  const LoginError(this.message, {this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? -1];
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
