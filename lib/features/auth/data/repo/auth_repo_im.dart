import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_local_data_source.dart';
import 'package:alatarekak/features/auth/data/data_source/auth_remote_data_source.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/auth/domain/repo/auth_repo.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/reset_password_params.dart';
import 'package:alatarekak/features/auth/domain/usecase/params/sing_up_params.dart';

class AuthRepoIm extends AuthRepo {
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthLocalDataSourceIm authLocalDataSourceIm;

  AuthRepoIm({
    required this.authRemoteDataSource,
    required this.authLocalDataSourceIm,
  });

  // ── Signup flow ──

  @override
  Future<Either<Filuar, Unit>> signIn(SignUpParams params) async {
    try {
      await authRemoteDataSource.singIn(params);
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, UserModel>> verifySinginOtp(
      String email, String otp) async {
    try {
      final user = await authRemoteDataSource.verifySinginOtp(email, otp);
      await authLocalDataSourceIm.saveUser(user);
      return right(user);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
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

  // ── Login flow ──

  @override
  Future<Either<Filuar, UserModel>> signInWithEmail(
      String email, String password) async {
    try {
      final user = await authRemoteDataSource.signInWithEmail(email, password);
      await authLocalDataSourceIm.saveUser(user);
      return right(user);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  // ── Forget password flow ──

  @override
  Future<Either<Filuar, Unit>> forgotPassword(String email) async {
    try {
      await authRemoteDataSource.forgotPassword(email);
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, Unit>> resendOtpForgetPassword(String email) async {
    // نفس الـ endpoint — يُعيد إرسال الـ OTP
    try {
      await authRemoteDataSource.forgotPassword(email);
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, String>> verifyOtpResetPassword(
      String email, String otp) async {
    try {
      final token = await authRemoteDataSource.verfiyOtpResetPassword(email, otp);
      return right(token);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, Unit>> resetPassword(ResetPasswordParams params) async {
    try {
      await authRemoteDataSource.resetPassword(params);
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  // ── Session ──

  @override
  Future<Either<Filuar, Unit>> refreshToken(String token) async {
    try {
      final tokens = await authRemoteDataSource.refreshToken(token);
      await authLocalDataSourceIm.updateTokens(
        tokens.accessToken,
        tokens.refreshToken,
      );
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, Unit>> logout() async {
    try {
      await authRemoteDataSource.logout();
      await authLocalDataSourceIm.clearAll();
      return right(unit);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
