
class Filuar {
  final String message;
  const Filuar({
    required this.message,
  });

  factory Filuar.fromJson(Map<String, dynamic> json) {
    return Filuar(
      message: json['message'] ??json['error']['message']??json['error'] ,
    );
  }
}
