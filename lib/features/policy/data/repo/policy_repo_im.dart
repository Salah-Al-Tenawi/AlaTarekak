import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/policy/data/data_source/policy_local_data_source.dart';
import 'package:alatarekak/features/policy/data/data_source/policy_remote_data_source.dart';
import 'package:alatarekak/features/policy/domain/entity/policy_content.dart';
import 'package:alatarekak/features/policy/domain/repo/policy_repo.dart';

class PolicyRepoIm extends PolicyRepo {
  final PolicyRemoteDataSource remoteDataSource;
  final PolicyLocalDataSource localDataSource;

  PolicyRepoIm({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  PolicyContent? getCached() => localDataSource.get();

  @override
  Future<Either<Filuar, PolicyContent>> getPolicies() async {
    try {
      final content = await remoteDataSource.getPolicies();
      await localDataSource.save(content);
      return right(content);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    } catch (e) {
      // شكل رد غير متوقع أو عطل تحويل — لا يصحّ أن ينهار التطبيق على
      // وثيقة نصّية، والمستدعي يعود إلى المخزَّن أو النسخة المدمجة
      return left(Filuar(message: e.toString()));
    }
  }
}
