import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/score/data/data_source/score_local_data_source.dart';
import 'package:alatarekak/features/score/data/data_source/score_remote_data_source.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:alatarekak/features/score/domain/repo/score_repo.dart';

class ScoreRepoIm extends ScoreRepo {
  final ScoreRemoteDataSource remoteDataSource;
  final ScoreLocalDataSource localDataSource;

  ScoreRepoIm({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  ScoreEntity? getCachedScore() => localDataSource.getScore();

  @override
  Future<Either<Filuar, ScoreEntity>> getScore() async {
    try {
      final score = await remoteDataSource.getScore();
      await localDataSource.saveScore(score);
      return right(score);
    } on ServerExpcptions catch (e) {
      // عند فشل الشبكة نرجع آخر نسخة مخزنة إن وُجدت
      final cached = localDataSource.getScore();
      if (cached != null) return right(cached);
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, List<ScoreHistoryEntity>>> getHistory(
      {int limit = 20}) async {
    try {
      return right(await remoteDataSource.getHistory(limit: limit));
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
