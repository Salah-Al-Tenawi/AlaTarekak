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
  final String accessToken;

  @HiveField(5)
  final String refreshToken;

  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.accessToken,
    required this.refreshToken,
  });

  factory UserModel.fromjson(Map<String, dynamic> json) {
    return UserModel(
      id: json[ApiKey.user][ApiKey.id],
      firstName: json[ApiKey.user][ApiKey.firstName],
      lastName: json[ApiKey.user][ApiKey.lastName],
      email: json[ApiKey.user][ApiKey.email],
      accessToken: json["tokens"]["access_token"],
      refreshToken: json["tokens"]["refresh_token"],
    );
  }
  UserModel copyWith({
  String? accessToken,
  String? refreshToken,
}) {
  return UserModel(
    id: id,
    firstName: firstName,
    lastName: lastName,
    email: email,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
  );
}
}