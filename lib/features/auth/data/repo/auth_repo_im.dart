import 'package:alatarekak/features/auth/domain/usecase/params/reset_password_params.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';
import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_local_data_source.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/domain/repo/auth_repo.dart';

class AuthRepoIm extends AuthRepo {
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthLocalDataSourceIm authLocalDataSourceIm;
  AuthRepoIm({
    required this.authRemoteDataSource,
    required this.authLocalDataSourceIm,
  });

  @override
  Future<Either<Filuar, Unit>> forgotPassword(String email) {
    // TODO: implement forgotPassword
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, Unit>> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, Unit>> resetPassword(ResetPasswordParams params) {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, Unit>> signIn(SignUpParams params) {
    // TODO: implement signIn
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, UserModel>> signInWithEmail(String email, String password) {
    // TODO: implement signInWithEmail
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, UserModel>> signInWithGoogle() {
    // TODO: implement signInWithGoogle
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, UserModel>> verifyEmail(String email, String otp) {
    // TODO: implement verifyEmail
    throw UnimplementedError();
  }




  // @override
  // Future<Either<Filuar, UserModel>> login(String email, String password) async {
  //   try {
  //     final user = await authRemoteDataSource.login(email, password);
  //     return right(user);
  //   } on ServerExpcptions catch (e) {
  //     return left(e.error);
  //   }
  // }

  // @override
  // Future<Either<Filuar, UserModel>> singin(
  //     String firstName,
  //     String lastName,
  //     String gender,
  //     String email,
  //     String address,
  //     String password,
  //     String verfiyPassword) async {
  //   try {
  //     final user = await authRemoteDataSource.singin(firstName, lastName,
  //         gender, email, address, password, verfiyPassword);
      
  //     return right(user);
  //   } on ServerExpcptions catch (e) {
  //     return left(e.error);
  //   }
  // }

  // @override
  // Future<Either<Filuar, dynamic>> forgetPassword(String email) async {
  //   try {
  //     final response = await authRemoteDataSource.forgetPassword(email);

  //     return right(response);
  //   } on ServerExpcptions catch (e) {
  //     return left(e.error);
  //   }
  // }

  // @override
  // Future<Either<Filuar, dynamic>> logout() async {
  //   try {
  //     final response = await authRemoteDataSource.logout();
  //     authLocalDataSourceIm.clearUser();
  //     return right(response);
  //   } on ServerExpcptions catch (e) {
  //     return left(e.error);
  //   }
  // }
  

}
