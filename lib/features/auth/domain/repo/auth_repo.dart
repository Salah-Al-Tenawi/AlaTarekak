import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

abstract class AuthRepo {
  Future<Either<Filuar, UserModel>> singin(
      String firstName,
      String lastName,
      String gender,
      String email,
      String address,
      String password,
      String verfiyPassword);

  Future<Either<Filuar, UserModel>> login(String email, String password);
  Future<Either<Filuar, dynamic>> logout();
  Future<Either<Filuar, dynamic>> forgetPassword(String email);
  // Future<Either<Filuar, UserModel>> singingWithGoogle();
}
