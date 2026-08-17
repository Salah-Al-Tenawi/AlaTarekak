part of 'score_cubit.dart';

sealed class ScoreState {}

final class ScoreInitial extends ScoreState {}

final class ScoreLoading extends ScoreState {}

final class ScoreLoaded extends ScoreState {
  final ScoreEntity score;
  ScoreLoaded({required this.score});
}

final class ScoreHistoryLoaded extends ScoreState {
  final ScoreEntity score;
  final List<ScoreHistoryEntity> history;

  /// بقيت صفحات في الخادم (`current_page < last_page`).
  final bool hasMore;

  /// الصفحة التالية في الطريق — تُظهر مؤشراً أسفل القائمة.
  final bool loadingMore;

  /// عدد الحركات كلها (`meta.total`) لا عدد المحمّل منها.
  final int total;

  ScoreHistoryLoaded({
    required this.score,
    required this.history,
    this.hasMore = false,
    this.loadingMore = false,
    this.total = 0,
  });
}

final class ScoreError extends ScoreState {
  final String message;
  ScoreError({required this.message});
}
