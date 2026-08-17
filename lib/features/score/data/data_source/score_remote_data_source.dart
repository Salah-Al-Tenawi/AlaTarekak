import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/api_envelope.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/score/data/model/score_model.dart';

abstract class ScoreRemoteDataSource {
  Future<ScoreModel> getScore();
  Future<ScoreHistoryPageModel> getHistory({int page, int perPage});
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

  /// `/score/transactions` — صفحة من سجلّ النقاط.
  ///
  /// الرد `{success, data: [...], meta: {total, per_page, current_page,
  /// last_page}}`، فتُقرأ الصفحة كاملة بترقيمها: القائمة وحدها لا تكفي
  /// لمعرفة هل بقي المزيد.
  @override
  Future<ScoreHistoryPageModel> getHistory({
    int page = 1,
    int perPage = 20,
  }) async {
    final json = await api.get(
      ApiEndPoint.scoreTransactions,
      queryParameters: {
        'page': page < 1 ? 1 : page,
        'per_page': perPage.clamp(1, 50),
      },
    );
    if (!ApiEnvelope.isOk(json)) _throwFrom(json);
    return ScoreHistoryPageModel.fromJson(json);
  }
}
