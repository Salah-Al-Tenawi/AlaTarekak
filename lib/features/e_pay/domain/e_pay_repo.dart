import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';

abstract class EPayRepo {
  
  Future<Either<Filuar, dynamic>> initWallet(
      String numberPhone, String password);
  Future<Either<Filuar, dynamic>> createWallet(
      String numberPhone, String otpCode);
  Future<Either<Filuar, dynamic>> getBalance();
}
