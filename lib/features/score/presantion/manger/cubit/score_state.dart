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
  ScoreHistoryLoaded({required this.score, required this.history});
}

final class ScoreError extends ScoreState {
  final String message;
  ScoreError({required this.message});
}
