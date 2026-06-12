import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/api_envelope.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/score/data/model/score_model.dart';

abstract class ScoreRemoteDataSource {
  Future<ScoreModel> getScore();
  Future<List<ScoreHistoryModel>> getHistory({int limit});
}

class ScoreRemoteDataSourceIm extends ScoreRemoteDataSource {
  final ApiConSumer api;

  ScoreRemoteDataSourceIm({required this.api});

  Never _throwFrom(dynamic json) {
    throw ServerExpcptions(
      error: json is Map<String, dynamic>
          ? Filuar.fromJson(json)
          : const Filuar(message: 'حدث خطأ غير متوقع'),
    );
  }

  @override
  Future<ScoreModel> getScore() async {
    final json = await api.get(ApiEndPoint.score);
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
    return ScoreModel.fromJson(
        (json as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  @override
  Future<List<ScoreHistoryModel>> getHistory({int limit = 20}) async {
    final json = await api.get(
      ApiEndPoint.scoreHistory,
      queryParameters: {'limit': limit.clamp(1, 50)},
    );
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
    final rawItems = (json as Map<String, dynamic>)['data'] as List? ?? [];
    return rawItems
        .whereType<Map<String, dynamic>>()
        .map(ScoreHistoryModel.fromJson)
        .toList();
  }
}
