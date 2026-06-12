import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:alatarekak/features/score/domain/repo/score_repo.dart';

part 'score_state.dart';

class ScoreCubit extends Cubit<ScoreState> {
  final ScoreRepo _repo;

  ScoreCubit(this._repo) : super(ScoreInitial());

  ScoreEntity? _cached;

  // ---------------------------------------------------------------
  // حارس الأزرار (§5.1 + قاعدة المستند رقم 9):
  // عطّل "إنشاء رحلة" عندما score < 50 و"الحجز" عندما score < 40
  // قبل الوصول للسيرفر. عند غياب البيانات نسمح (السيرفر سيحسم).
  // ---------------------------------------------------------------

  bool get canCreateRides => _cached?.canCreateRides ?? true;
  bool get canBookRides => _cached?.canBookRides ?? true;
  ScoreEntity? get currentScore => _cached;

  static const String cannotCreateMessage =
      "نقاط الثقة لديك غير كافية لإنشاء رحلات (الحد الأدنى 50)";
  static const String cannotBookMessage =
      "نقاط الثقة لديك غير كافية لحجز الرحلات (الحد الأدنى 40)";

  /// §5.1 — جلب النقاط: الكاش يُعرض فوراً ثم يُحدَّث من الشبكة
  Future<void> load() async {
    final cached = _repo.getCachedScore();
    if (cached != null) {
      _cached = cached;
      emit(ScoreLoaded(score: cached));
    } else {
      emit(ScoreLoading());
    }

    final result = await _repo.getScore();
    if (isClosed) return;

    result.fold(
      (failure) => emit(
          ScoreError(message: HandelErorrMessage.errServer)),
      (score) {
        _cached = score;
        emit(ScoreLoaded(score: score));
      },
    );
  }

  /// §5.2 — جلب السجل (يتطلب تحميل النقاط أولاً أو يجلبها تلقائياً)
  Future<void> loadHistory({int limit = 20}) async {
    if (_cached == null) {
      final scoreResult = await _repo.getScore();
      if (isClosed) return;
      scoreResult.fold((_) {}, (s) => _cached = s);
      if (_cached == null) {
        emit(ScoreError(message: HandelErorrMessage.errServer));
        return;
      }
    }

    final result = await _repo.getHistory(limit: limit);
    if (isClosed) return;

    result.fold(
      (failure) =>
          emit(ScoreError(message: HandelErorrMessage.errServer)),
      (history) =>
          emit(ScoreHistoryLoaded(score: _cached!, history: history)),
    );
  }

  /// تحديث صامت بعد عمليات تغيّر النقاط (إلغاء رحلة/حجز، إكمال رحلة...)
  Future<void> refreshSilently() async {
    final result = await _repo.getScore();
    if (isClosed) return;
    result.fold((_) {}, (score) {
      _cached = score;
      if (state is ScoreLoaded) emit(ScoreLoaded(score: score));
    });
  }
}
