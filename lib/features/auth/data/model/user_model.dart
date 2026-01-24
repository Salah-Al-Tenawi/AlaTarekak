// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:hive/hive.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String firstName;

  @HiveField(2)
  final String lastName;

  @HiveField(3)
  final String email;

  @HiveField(4)
  final String gender;

  @HiveField(5)
  final String address;

  @HiveField(6)
  final String token;
  const UserModel(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.gender,
      required this.address,
      required this.token});

  factory UserModel.fromjson(Map<String, dynamic> json) {
    return UserModel(
        id: json[ApiKey.user][ApiKey.id],
        firstName: json[ApiKey.user][ApiKey.firstName],
        lastName: json[ApiKey.user][ApiKey.lastName],
        email: json[ApiKey.user][ApiKey.email],
        gender: json[ApiKey.user][ApiKey.gender],
        address: json[ApiKey.user][ApiKey.address],
        token: json[ApiKey.token]);
  }
}
