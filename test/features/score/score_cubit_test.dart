import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/score/domain/entity/score_entity.dart';
import 'package:alatarekak/features/score/domain/repo/score_repo.dart';
import 'package:alatarekak/features/score/presantion/manger/cubit/score_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockScoreRepo extends Mock implements ScoreRepo {}

ScoreEntity _score(int value) => ScoreEntity(
      score: value,
      tier: 'silver',
      cancelRate: 0.1,
      totalRides: 10,
      totalCancellations: 1,
      canCreateRides: value >= 50,
      canBookRides: value >= 40,
    );

void main() {
  late MockScoreRepo repo;

  setUp(() {
    repo = MockScoreRepo();
  });

  group('ScoreCubit — نقاط الثقة (BR: إنشاء ≥50، حجز ≥40)', () {
    test('قبل التحميل: الحارس يسمح بالكل (السيرفر يحسم)', () {
      when(() => repo.getCachedScore()).thenReturn(null);
      final cubit = ScoreCubit(repo);

      expect(cubit.canCreateRides, isTrue);
      expect(cubit.canBookRides, isTrue);
    });

    blocTest<ScoreCubit, ScoreState>(
      'بلا كاش: Loading ثم Loaded من الشبكة، والحارس يعكس النقاط',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(null);
        when(() => repo.getScore())
            .thenAnswer((_) async => right(_score(45)));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ScoreLoading>(),
        isA<ScoreLoaded>().having((s) => s.score.score, 'score', 45),
      ],
      verify: (cubit) {
        // 45: يكفي للحجز (≥40) لكن لا يكفي لإنشاء رحلة (<50)
        expect(cubit.canBookRides, isTrue);
        expect(cubit.canCreateRides, isFalse);
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'مع كاش: يعرض الكاش فوراً ثم يحدّث من الشبكة (عرضان)',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(_score(60));
        when(() => repo.getScore())
            .thenAnswer((_) async => right(_score(65)));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ScoreLoaded>().having((s) => s.score.score, 'من الكاش', 60),
        isA<ScoreLoaded>().having((s) => s.score.score, 'من الشبكة', 65),
      ],
    );

    blocTest<ScoreCubit, ScoreState>(
      'فشل الشبكة بلا كاش: ScoreError برسالة عامة',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(null);
        when(() => repo.getScore()).thenAnswer(
            (_) async => left(const Filuar(message: 'Server error')));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ScoreLoading>(),
        isA<ScoreError>().having(
            (s) => s.message, 'message', HandelErorrMessage.errServer),
      ],
    );

    // كانت كل الإخفاقات تُعرض «حدث خطأ غير متوقع» لأن الكيوبت يكتب
    // errServer ثابتاً ويرمي رسالة الخادم — فمن انتهت جلسته لا يعرف
    // أن عليه تسجيل الدخول، ومن تجاوز الحدّ لا يعرف أن عليه الانتظار.
    blocTest<ScoreCubit, ScoreState>(
      'جلسة منتهية تُقال للمستخدم لا تُخفى خلف الرسالة العامة',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(null);
        when(() => repo.getScore()).thenAnswer(
            (_) async => left(const Filuar(message: 'Unauthenticated.')));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ScoreLoading>(),
        isA<ScoreError>()
            .having((s) => s.message, 'message', HandelErorrMessage.errSession)
            .having((s) => s.message, 'ليست العامة',
                isNot(HandelErorrMessage.errServer)),
      ],
    );

    blocTest<ScoreCubit, ScoreState>(
      'فشل جلب النقاط قبل السجل يحمل سببه هو أيضاً',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(null);
        when(() => repo.getScore()).thenAnswer(
            (_) async => left(const Filuar(message: 'Unauthenticated.')));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<ScoreError>().having(
            (s) => s.message, 'message', HandelErorrMessage.errSession),
      ],
    );

    blocTest<ScoreCubit, ScoreState>(
      'فشل جلب السجل نفسه: لا تصل رسالة الخادم الإنجليزية للشاشة',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(_score(55));
        when(() => repo.getScore())
            .thenAnswer((_) async => right(_score(55)));
        when(() => repo.getHistory(
                page: any(named: 'page'), perPage: any(named: 'perPage')))
            .thenAnswer((_) async =>
                left(const Filuar(message: 'Too Many Attempts. Retry in 12 seconds')));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.loadHistory(),
      verify: (cubit) {
        final state = cubit.state as ScoreError;
        expect(state.message, contains('12 ثانية'));
        expect(state.message, isNot(contains('Too Many')));
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'سجل النقاط: يجلب النقاط أولاً إن لم تكن محملة ثم يعرض السجل',
      build: () {
        when(() => repo.getScore())
            .thenAnswer((_) async => right(_score(55)));
        _stubHistory(repo, _page([_entry(id: 1)]));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<ScoreHistoryLoaded>()
            .having((s) => s.history.length, 'عدد السجل', 1)
            .having((s) => s.history.first.isPositive, 'إيجابي', isTrue),
      ],
    );
  });

  // ---------------------------------------------------------------
  // الترقيم: /score/transactions يرسل 20 حركة في الصفحة و`meta` تقول
  // كم بقي. بلا هذا يرى المستخدم أول 20 حركة فقط ويظنّها سجلّه كله.
  // ---------------------------------------------------------------

  group('ScoreCubit — صفحات السجلّ', () {
    setUp(() {
      when(() => repo.getCachedScore()).thenReturn(_score(55));
      when(() => repo.getScore()).thenAnswer((_) async => right(_score(55)));
    });

    blocTest<ScoreCubit, ScoreState>(
      'الصفحة الأولى تحمل ترقيمها: بقيت صفحات، والإجمالي من meta',
      build: () {
        _stubHistory(repo, _page([_entry(id: 1)], total: 84, lastPage: 5));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<ScoreHistoryLoaded>()
            .having((s) => s.hasMore, 'بقي المزيد', isTrue)
            .having((s) => s.total, 'الإجمالي', 84),
      ],
      verify: (_) {
        verify(() => repo.getHistory(page: 1, perPage: any(named: 'perPage')))
            .called(1);
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'التالية تُضاف لما قبلها ولا تستبدله',
      build: () {
        when(() => repo.getHistory(
                page: 1, perPage: any(named: 'perPage')))
            .thenAnswer((_) async =>
                right(_page([_entry(id: 1), _entry(id: 2)], total: 4, lastPage: 2)));
        when(() => repo.getHistory(
                page: 2, perPage: any(named: 'perPage')))
            .thenAnswer((_) async => right(_page(
                [_entry(id: 3), _entry(id: 4)],
                total: 4,
                currentPage: 2,
                lastPage: 2)));
        return ScoreCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadHistory();
        await cubit.loadMoreHistory();
      },
      expect: () => [
        isA<ScoreHistoryLoaded>().having((s) => s.history.length, 'صفحة', 2),
        isA<ScoreHistoryLoaded>()
            .having((s) => s.loadingMore, 'جارٍ الجلب', isTrue),
        isA<ScoreHistoryLoaded>()
            .having((s) => s.history.map((e) => e.id).toList(), 'الصفحتان معاً',
                [1, 2, 3, 4])
            .having((s) => s.hasMore, 'انتهى السجل', isFalse)
            .having((s) => s.loadingMore, 'انتهى الجلب', isFalse),
      ],
    );

    blocTest<ScoreCubit, ScoreState>(
      'لا طلب لصفحة بعد الأخيرة',
      build: () {
        _stubHistory(repo, _page([_entry(id: 1)], total: 1, lastPage: 1));
        return ScoreCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadHistory();
        await cubit.loadMoreHistory();
      },
      expect: () => [isA<ScoreHistoryLoaded>()],
      verify: (_) {
        verifyNever(() =>
            repo.getHistory(page: 2, perPage: any(named: 'perPage')));
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'صفّ مكرّر على حدّ الصفحتين لا يُعرض مرتين',
      build: () {
        when(() => repo.getHistory(page: 1, perPage: any(named: 'perPage')))
            .thenAnswer((_) async =>
                right(_page([_entry(id: 1), _entry(id: 2)], lastPage: 2)));
        // حركة جديدة أُدرجت بين الطلبين فأزاحت الترقيم: id=2 يعود ثانيةً
        when(() => repo.getHistory(page: 2, perPage: any(named: 'perPage')))
            .thenAnswer((_) async => right(_page(
                [_entry(id: 2), _entry(id: 3)],
                currentPage: 2,
                lastPage: 2)));
        return ScoreCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadHistory();
        await cubit.loadMoreHistory();
      },
      verify: (cubit) {
        final state = cubit.state as ScoreHistoryLoaded;
        expect(state.history.map((e) => e.id).toList(), [1, 2, 3]);
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'فشل جلب التالية يُبقي المعروض ولا يمسح الشاشة',
      build: () {
        when(() => repo.getHistory(page: 1, perPage: any(named: 'perPage')))
            .thenAnswer(
                (_) async => right(_page([_entry(id: 1)], lastPage: 2)));
        when(() => repo.getHistory(page: 2, perPage: any(named: 'perPage')))
            .thenAnswer(
                (_) async => left(const Filuar(message: 'Server error')));
        return ScoreCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadHistory();
        await cubit.loadMoreHistory();
      },
      verify: (cubit) {
        expect(cubit.state, isA<ScoreHistoryLoaded>());
        final state = cubit.state as ScoreHistoryLoaded;
        expect(state.history, hasLength(1));
        expect(state.loadingMore, isFalse);
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'فشل السحب للتحديث فوق سجلّ معروض يُبقيه بدل رسالة خطأ',
      build: () {
        _stubHistory(repo, _page([_entry(id: 1)]));
        return ScoreCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadHistory();
        when(() => repo.getHistory(
                page: any(named: 'page'), perPage: any(named: 'perPage')))
            .thenAnswer(
                (_) async => left(const Filuar(message: 'Server error')));
        await cubit.loadHistory();
      },
      verify: (cubit) {
        expect(cubit.state, isA<ScoreHistoryLoaded>(),
            reason: 'بيانات صالحة أمام المستخدم لا تُمسح لأجل تحديث فاشل');
        expect((cubit.state as ScoreHistoryLoaded).history, hasLength(1));
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'الصفحة الأولى تُستبدل عند إعادة التحميل ولا تتراكم',
      build: () {
        _stubHistory(repo, _page([_entry(id: 1), _entry(id: 2)]));
        return ScoreCubit(repo);
      },
      act: (cubit) async {
        await cubit.loadHistory();
        await cubit.loadHistory();
      },
      verify: (cubit) {
        expect((cubit.state as ScoreHistoryLoaded).history, hasLength(2));
      },
    );
  });

  // ---------------------------------------------------------------
  // الكاش: الرأس كان يظهر بالرقم المخزَّن بينما يبقى السجل تحته فارغاً
  // حتى يردّ الخادم — أو أبداً بلا شبكة.
  // ---------------------------------------------------------------

  group('ScoreCubit — سجلّ مخزَّن', () {
    blocTest<ScoreCubit, ScoreState>(
      'يُعرض فوراً قبل ردّ الشبكة ثم يُستبدل به',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(_score(55));
        when(() => repo.getCachedHistory())
            .thenReturn(_page([_entry(id: 99)]));
        when(() => repo.getScore()).thenAnswer((_) async => right(_score(60)));
        _stubHistory(repo, _page([_entry(id: 1)], total: 84, lastPage: 5));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<ScoreHistoryLoaded>()
            .having((s) => s.history.single.id, 'من الكاش', 99)
            .having((s) => s.hasMore, 'الكاش لا يخمّن الترقيم', isFalse),
        isA<ScoreHistoryLoaded>()
            .having((s) => s.history.single.id, 'من الشبكة', 1)
            .having((s) => s.total, 'الإجمالي الحقيقي', 84)
            .having((s) => s.hasMore, 'صحّحه التحديث', isTrue),
      ],
    );

    blocTest<ScoreCubit, ScoreState>(
      'بلا شبكة يبقى المخزَّن معروضاً بدل شاشة خطأ',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(_score(55));
        when(() => repo.getCachedHistory())
            .thenReturn(_page([_entry(id: 99)]));
        when(() => repo.getScore()).thenAnswer((_) async => right(_score(55)));
        when(() => repo.getHistory(
                page: any(named: 'page'), perPage: any(named: 'perPage')))
            .thenAnswer(
                (_) async => left(const Filuar(message: 'تحقق من اتصالك')));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.loadHistory(),
      verify: (cubit) {
        expect(cubit.state, isA<ScoreHistoryLoaded>());
        expect((cubit.state as ScoreHistoryLoaded).history.single.id, 99);
      },
    );

    blocTest<ScoreCubit, ScoreState>(
      'بلا كاش يبقى السلوك كما كان — لا عرض قبل الشبكة',
      build: () {
        when(() => repo.getCachedScore()).thenReturn(null);
        when(() => repo.getCachedHistory()).thenReturn(null);
        when(() => repo.getScore()).thenAnswer((_) async => right(_score(55)));
        _stubHistory(repo, _page([_entry(id: 1)]));
        return ScoreCubit(repo);
      },
      act: (cubit) => cubit.loadHistory(),
      expect: () => [
        isA<ScoreHistoryLoaded>().having((s) => s.history.single.id, 'id', 1),
      ],
    );
  });
}

// ─── مساعدات ─────────────────────────────────────────────────────────────────

ScoreHistoryEntity _entry({required int id}) => ScoreHistoryEntity(
      id: id,
      action: 'ride_completed',
      points: '+5',
      previousScore: 50,
      newScore: 55,
      reason: 'Ride completed',
    );

ScoreHistoryPage _page(
  List<ScoreHistoryEntity> items, {
  int? total,
  int currentPage = 1,
  int lastPage = 1,
}) =>
    ScoreHistoryPage(
      items: items,
      total: total ?? items.length,
      perPage: 20,
      currentPage: currentPage,
      lastPage: lastPage,
    );

void _stubHistory(MockScoreRepo repo, ScoreHistoryPage page) {
  when(() => repo.getHistory(
          page: any(named: 'page'), perPage: any(named: 'perPage')))
      .thenAnswer((_) async => right(page));
}
