import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/e_pay/data/data_source/e_pay_remote_data_source.dart';
import 'package:alatarekak/features/e_pay/data/model/balance_model.dart';
import 'package:alatarekak/features/e_pay/domain/e_pay_repo.dart';

class EPayRepoIm extends EPayRepo {
  final EPayRemoteDataSource remoteDataSource;

  EPayRepoIm({required this.remoteDataSource});

  @override
  Future<Either<Filuar, dynamic>> initWallet(
      String numberPhone, String password) async {
    try {
      final response = await remoteDataSource.initWallet(numberPhone, password);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, dynamic>> createWallet(
      String numberPhone, String otpCode) async {
    try {
      final response =
          await remoteDataSource.createWallet(numberPhone, otpCode);
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
