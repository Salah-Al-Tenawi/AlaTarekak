import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';

abstract class ScoreRepo {
  /// آخر نسخة مخزنة محلياً (متاحة فوراً وبدون شبكة) — null إن لم تُخزن بعد
  ScoreEntity? getCachedScore();

  /// §5.1 — النقاط الحالية وصلاحيات الإنشاء/الحجز
  /// (تُخزن تلقائياً، وتسقط للكاش عند فشل الشبكة)
  Future<Either<Filuar, ScoreEntity>> getScore();

  /// آخر صفحة أولى مخزَّنة من السجل — تُعرض فوراً وبلا شبكة، ثم تُستبدل
  /// بما يردّه الخادم. `null` إن لم يُخزَّن شيء بعد.
  ScoreHistoryPage? getCachedHistory();

  /// §5.2 — صفحة من سجل التغيرات (`/score/transactions`).
  /// تُرجع الصفحة بترقيمها لا القائمة وحدها، فالسجل قد يتجاوز مئة حركة.
  Future<Either<Filuar, ScoreHistoryPage>> getHistory({
    int page = 1,
    int perPage = 20,
  });
}
