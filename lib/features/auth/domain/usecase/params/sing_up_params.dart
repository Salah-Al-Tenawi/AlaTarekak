class SignUpParams {
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String address;
  final String password;
  final String confirmPassword;

  /// رقم الهاتف (09XXXXXXXX) — تُنشأ عليه محفظة المستخدم تلقائياً بعد
  /// تأكيد البريد. لا يُرسل ضمن جسم /auth/signup لأن الخادم لا يتوقعه.
  final String phoneNumber;

  SignUpParams({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.address,
    required this.password,
    required this.confirmPassword,
    required this.phoneNumber,
  });
}
