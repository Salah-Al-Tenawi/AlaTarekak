import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';

abstract class ScoreRepo {
  /// آخر نسخة مخزنة محلياً (متاحة فوراً وبدون شبكة) — null إن لم تُخزن بعد
  ScoreEntity? getCachedScore();

  /// §5.1 — النقاط الحالية وصلاحيات الإنشاء/الحجز
  /// (تُخزن تلقائياً، وتسقط للكاش عند فشل الشبكة)
  Future<Either<Filuar, ScoreEntity>> getScore();

  /// §5.2 — سجل التغيرات (limit أقصاه 50)
  Future<Either<Filuar, List<ScoreHistoryEntity>>> getHistory({int limit = 20});
}
