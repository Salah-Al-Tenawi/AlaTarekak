import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/e_pay/domain/entity/wallet_transaction.dart';

abstract class EPayRepo {
  
  Future<Either<Filuar, dynamic>> createWalletDirect(String phoneNumber);
  Future<Either<Filuar, dynamic>> getBalance();
  Future<Either<Filuar, WalletStatement>> getTransactions({int page, int perPage});
}
