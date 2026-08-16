import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/e_pay/data/data_source/e_pay_remote_data_source.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/domain/e_pay_repo.dart';
import 'package:alatarekak/features/e_pay/domain/entity/wallet_transaction.dart';

class EPayRepoIm extends EPayRepo {
  final EPayRemoteDataSource remoteDataSource;

  EPayRepoIm({required this.remoteDataSource});

  @override
  Future<Either<Filuar, dynamic>> createWalletDirect(String phoneNumber) async {
    try {
      final response = await remoteDataSource.createWalletDirect(phoneNumber);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, WalletStatement>> getTransactions(
      {int page = 1, int perPage = 15}) async {
    try {
      final response =
          await remoteDataSource.getTransactions(page: page, perPage: perPage);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, BalanceModel>> getBalance() async {
    try {
      final response = await remoteDataSource.getBalance();
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
