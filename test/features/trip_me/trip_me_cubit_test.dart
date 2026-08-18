import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_me/data/repo/trip_me_repo_im.dart';
import 'package:alatarekak/features/trip_me/presantion/manger/cubit/trip_me_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockTripMeRepo extends Mock implements TripMeRepoIm {}

void main() {
  late MockTripMeRepo repo;

  setUp(() {
    repo = MockTripMeRepo();
  });

  group('TripMeCubit — رحلاتي (السائق)', () {
    blocTest<TripMeCubit, TripMeState>(
      'نجاح جلب رحلاتي: Loading ثم ListLoaded',
      build: () {
        when(() => repo.showAllTrip())
            .thenAnswer((_) async => right([fakeTrip(), fakeTrip(id: 6)]));
        return TripMeCubit(repo);
      },
      act: (cubit) => cubit.getMeTrips(),
      expect: () => [
        isA<TripMeLoading>(),
        isA<TripMeListLoaded>()
            .having((s) => s.trips.length, 'عدد الرحلات', 2),
      ],
    );

  });

  group('TripMeCubit — إلغاء رحلة', () {
    blocTest<TripMeCubit, TripMeState>(
      'نجاح الإلغاء: Cancel ثم إعادة تحميل القائمة تلقائياً',
      build: () {
        when(() => repo.cancelTrip(5)).thenAnswer((_) async => right(null));
        when(() => repo.showAllTrip()).thenAnswer((_) async => right([]));
        return TripMeCubit(repo);
      },
      act: (cubit) => cubit.cancelTrip(5),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<TripMeLoading>(),
        isA<TripMeCancel>(),
        isA<TripMeLoading>(),
        isA<TripMeListLoaded>(),
      ],
      verify: (_) => verify(() => repo.showAllTrip()).called(1),
    );

    blocTest<TripMeCubit, TripMeState>(
      'فشل الإلغاء قبل أقل من ساعة: رسالة معرّبة',
      build: () {
        when(() => repo.cancelTrip(any())).thenAnswer((_) async => left(
            const Filuar(
                message:
                    'Cannot cancel less than 1 hour before departure')));
        return TripMeCubit(repo);
      },
      act: (cubit) => cubit.cancelTrip(5),
      expect: () => [
        isA<TripMeLoading>(),
        isA<TripMeErorr>().having((s) => s.message, 'message',
            'لا يمكن إلغاء الرحلة قبل أقل من ساعة من موعد الانطلاق'),
      ],
    );
  });
}
