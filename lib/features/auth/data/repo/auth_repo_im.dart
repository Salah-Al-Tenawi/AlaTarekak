import 'package:alatarekak/features/auth/data/model/token_model.dart';
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
  Future<Either<Filuar, Unit>> forgotPassword(String email)async {
    try{
      final response= await authRemoteDataSource.forgotPassword(email);
      return right(response);
    }
    on ServerExpcptions catch(e){ 
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, Unit>> logout()async {
   try {
      final response = await authRemoteDataSource.logout();
      authLocalDataSourceIm.clearAll();
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, Unit>> resetPassword(ResetPasswordParams params) {
    // TODO: implement resetPassword
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, Unit>> signIn(SignUpParams params) async{
   try {
      final user = await authRemoteDataSource.singIn(params);
      
      return right(user);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, UserModel>> signInWithEmail(String email, String password)async {
     try {
      final user = await authRemoteDataSource.signInWithEmail(email, password);
      return right(user);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, UserModel>> signInWithGoogle() {
    // TODO: implement signInWithGoogle
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, UserModel>> verifySinginOtp(String email, String otp)async {
   try{ 
    final user =await authRemoteDataSource.verifySinginOtp(email, otp);
    return right(user);
   }
   on ServerExpcptions catch(e){ 
    return left(e.error);
   }


  }

@override
  Future<Either<Filuar,Unit>> refreshToken(String token)async{ 
  try{ 
 await authRemoteDataSource.refreshToken(token);
return right(unit);
  }
  on ServerExpcptions catch(e){
     return left(e.error);
  }
}

  @override
  Future<Either<Filuar, Unit>> verifyForgetPasswordOtp(String email, String otp) {
    // TODO: implement verifyForgetPasswordOtp
    throw UnimplementedError();
  }

  @override
  Future<Either<Filuar, Unit>> resendOtpSinging(String email) async {
    try {
      await authRemoteDataSource.resendOtpSinging(email);
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
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
