import 'dart:convert';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/score/data/model/score_model.dart';

abstract class ScoreLocalDataSource {
  ScoreModel? getScore();
  Future<void> saveScore(ScoreModel score);
  Future<void> clear();
}

class ScoreLocalDataSourceIm extends ScoreLocalDataSource {
  @override
  ScoreModel? getScore() {
    final raw = HiveBoxes.cacheBox.get(HiveKeys.score);
    if (raw == null) return null;
    try {
      return ScoreModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveScore(ScoreModel score) =>
      HiveBoxes.cacheBox.put(HiveKeys.score, jsonEncode(score.toJson()));

  @override
  Future<void> clear() => HiveBoxes.cacheBox.delete(HiveKeys.score);
}
