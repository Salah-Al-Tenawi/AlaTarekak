import 'dart:convert';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/score/data/model/score_model.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';

abstract class ScoreLocalDataSource {
  ScoreModel? getScore();
  Future<void> saveScore(ScoreModel score);

  /// الصفحة الأولى من سجلّ الحركات — تكفي للعرض الفوري، والباقي يُجلب
  /// من الشبكة بالترقيم.
  ///
  /// النقاط كانت مخزَّنة والسجل لا: يُفتح الرأس فوراً بالرقم القديم ثم
  /// يبقى ما تحته فارغاً حتى يردّ الخادم — أو أبداً إن تعذّرت الشبكة.
  ScoreHistoryPage? getHistoryFirstPage();
  Future<void> saveHistoryFirstPage(ScoreHistoryPage page);

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
  ScoreHistoryPage? getHistoryFirstPage() {
    final raw = HiveBoxes.cacheBox.get(HiveKeys.scoreHistory);
    if (raw == null) return null;
    try {
      final items = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => ScoreHistoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (items.isEmpty) return null;
      return ScoreHistoryPage(
        items: items,
        total: items.length,
        currentPage: 1,
        // الكاش لا يعرف كم بقي عند الخادم — التحديث الشبكي يصحّح
        // `hasMore` وإجمالي الحركات
        lastPage: 1,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveHistoryFirstPage(ScoreHistoryPage page) =>
      HiveBoxes.cacheBox.put(
        HiveKeys.scoreHistory,
        jsonEncode(page.items
            .whereType<ScoreHistoryModel>()
            .map((e) => e.toJson())
            .toList()),
      );

  @override
  Future<void> clear() => Future.wait([
        HiveBoxes.cacheBox.delete(HiveKeys.score),
        HiveBoxes.cacheBox.delete(HiveKeys.scoreHistory),
      ]);
}
