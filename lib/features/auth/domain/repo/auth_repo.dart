import 'package:alatarekak/features/auth/domain/usecase/params/reset_password_params.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';
import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';

abstract class AuthRepo {
   Future<Either<Filuar, Unit>> signIn(SignUpParams params);
  Future<Either<Filuar, UserModel>> signInWithEmail(String email, String password);
  Future<Either<Filuar, UserModel>> signInWithGoogle();


  Future<Either<Filuar, Unit>> logout();
  Future<Either<Filuar, Unit>> forgotPassword(String email);
  Future<Either<Filuar, UserModel>> verifyEmail(String email ,String otp);
  
  Future<Either<Filuar, Unit>> resetPassword(ResetPasswordParams params);
}
