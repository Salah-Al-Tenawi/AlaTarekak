
class ResetPasswordParams {
  final String email;
  final String otp;
  final String newPassword;
  final String confirmPassword;

  ResetPasswordParams({
    required this.email,
    required this.otp,
    required this.newPassword,
    required this.confirmPassword,
  });
}

