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

    blocTest<ScoreCubit, ScoreState>(
      'سجل النقاط: يجلب النقاط أولاً إن لم تكن محملة ثم يعرض السجل',
      build: () {
        when(() => repo.getScore())
            .thenAnswer((_) async => right(_score(55)));
        when(() => repo.getHistory(limit: any(named: 'limit')))
            .thenAnswer((_) async => right([
                  const ScoreHistoryEntity(
                    id: 1,
                    action: 'ride_completed',
                    points: '+5',
                    previousScore: 50,
                    newScore: 55,
                    reason: 'إكمال رحلة',
                  ),
                ]));
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
}
