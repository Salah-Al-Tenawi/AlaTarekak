import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';

abstract class EPayRepo {
  
  Future<Either<Filuar, dynamic>> createWalletDirect(String phoneNumber);
  Future<Either<Filuar, dynamic>> getBalance();
}
