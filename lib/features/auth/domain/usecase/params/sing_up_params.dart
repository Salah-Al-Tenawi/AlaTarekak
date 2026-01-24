
class SignUpParams {
  final String firstName;
  final String lastName;
  final String gender;
  final String email;
  final String address;
  final String password;
  final String confirmPassword; 

  SignUpParams({
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.email,
    required this.address,
    required this.password,
    required this.confirmPassword,
  });
}
