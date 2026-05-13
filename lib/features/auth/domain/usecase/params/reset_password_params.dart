
class ResetPasswordParams {
  final String resetToken;
  
  final String newPassword;
  final String confirmPassword;

  ResetPasswordParams({
    required this.resetToken,
    
    required this.newPassword,
    required this.confirmPassword,
  });
}

