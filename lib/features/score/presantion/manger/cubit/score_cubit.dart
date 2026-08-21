import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:alatarekak/features/score/domain/repo/score_repo.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'score_state.dart';

class ScoreCubit extends SafeCubit<ScoreState> {
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
      (failure) =>
          emit(ScoreError(message: failure.arabic(HandelErorrMessage.score))),
      (score) {
        _cached = score;
        emit(ScoreLoaded(score: score));
      },
    );
  }

  // ---------------------------------------------------------------
  // سجلّ الحركات (§5.2) — `/score/transactions` مُرقَّم، فالسجل يتراكم
  // بلا حدّ ولا يصلح جلبه دفعة واحدة.
  // ---------------------------------------------------------------

  static const int _perPage = 20;

  final List<ScoreHistoryEntity> _history = [];
  int _currentPage = 1;
  int _total = 0;
  bool _hasMore = false;
  bool _isLoadingMore = false;

  /// §5.2 — الصفحة الأولى (يتطلب تحميل النقاط أولاً أو يجلبها تلقائياً).
  /// تُستدعى أيضاً عند السحب للتحديث فتبدأ الترقيم من جديد.
  Future<void> loadHistory() async {
    // النقاط والسجل المخزَّنان يُعرضان فوراً — كان الرأس يظهر بالرقم
    // القديم بينما يبقى ما تحته فارغاً حتى يردّ الخادم، أو أبداً بلا شبكة
    if (_history.isEmpty) {
      final cachedScore = _repo.getCachedScore();
      final cachedHistory = _repo.getCachedHistory();
      if (cachedScore != null && cachedHistory != null) {
        _cached = cachedScore;
        _history.addAll(cachedHistory.items);
        _total = cachedHistory.total;
        _hasMore = false; // الكاش لا يعرف كم بقي — التحديث الشبكي يصحّح
        _emitHistory();
      }
    }

    if (_cached == null) {
      final scoreResult = await _repo.getScore();
      if (isClosed) return;
      // سبب الفشل يُحمل معه: «انتهت الجلسة» و«محاولات كثيرة» ليستا
      // «خطأ غير متوقع»، والمستخدم يتصرّف بناءً على الفرق
      String? failureMessage;
      scoreResult.fold((f) => failureMessage = f.message, (s) => _cached = s);
      if (_cached == null) {
        emit(ScoreError(
            message: HandelErorrMessage.score(failureMessage ?? '')));
        return;
      }
    }

    final result = await _repo.getHistory(page: 1, perPage: _perPage);
    if (isClosed) return;

    result.fold(
      (failure) {
        // فشل السحب للتحديث فوق سجلّ معروض: إبقاؤه أصدق من مسح الشاشة
        // كلها ووضع رسالة خطأ مكان بيانات ما زالت صالحة.
        if (_history.isNotEmpty) {
          _emitHistory();
        } else {
          emit(ScoreError(
              message: failure.arabic(HandelErorrMessage.score)));
        }
      },
      (page) {
        _history
          ..clear()
          ..addAll(page.items);
        _currentPage = page.currentPage;
        _total = page.total;
        _hasMore = page.hasMore;
        _isLoadingMore = false;
        _emitHistory();
      },
    );
  }

  /// الصفحة التالية عند بلوغ نهاية القائمة.
  Future<void> loadMoreHistory() async {
    if (!_hasMore || _isLoadingMore || state is! ScoreHistoryLoaded) return;
    _isLoadingMore = true;
    _emitHistory();

    final result =
        await _repo.getHistory(page: _currentPage + 1, perPage: _perPage);
    if (isClosed) return;
    _isLoadingMore = false;

    result.fold(
      (_) => _emitHistory(), // فشل صامت — نبقي ما حُمّل
      (page) {
        _currentPage = page.currentPage > _currentPage
            ? page.currentPage
            : _currentPage + 1;
        // حركة جديدة تُسجَّل بين طلبين تُزيح الترقيم فيتكرر صفّ على حدّ
        // الصفحة — نُسقطه بالمعرّف بدل عرضه مرتين.
        final seen = _history.map((e) => e.id).toSet();
        _history.addAll(page.items.where((e) => !seen.contains(e.id)));
        _total = page.total;
        _hasMore = page.hasMore;
        _emitHistory();
      },
    );
  }

  void _emitHistory() {
    final score = _cached;
    if (score == null) return;
    emit(ScoreHistoryLoaded(
      score: score,
      history: List.unmodifiable(_history),
      hasMore: _hasMore,
      loadingMore: _isLoadingMore,
      total: _total,
    ));
  }

  /// تحديث صامت بعد عمليات تغيّر النقاط (إلغاء رحلة/حجز، إكمال رحلة...)
  Future<void> refreshSilently() async {
    final result = await _repo.getScore();
    if (isClosed) return;
    result.fold((_) {}, (score) {
      _cached = score;
      if (state is ScoreLoaded) emit(ScoreLoaded(score: score));
      // الرأس يعرض النقاط فوق السجل — تحديثها يجب أن يصل للشاشتين
      if (state is ScoreHistoryLoaded) _emitHistory();
    });
  }
}
