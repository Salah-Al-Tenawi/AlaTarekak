import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/trip_search/data/repo/search_repo_im.dart';
import 'package:alatarekak/features/trip_search/presantion/manger/cubit/search_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockSearchRepo extends Mock implements SearchRepoIm {}

void main() {
  late MockSearchRepo repo;

  setUp(() {
    repo = MockSearchRepo();
  });

  group('SearchCubit — البحث عن رحلات', () {
    blocTest<SearchCubit, SearchState>(
      'نجاح البحث: Loading ثم Succes بقائمة الرحلات',
      build: () {
        when(() => repo.search(
                '33.51', '36.29', '34.73', '36.71', '2026-07-15', 2))
            .thenAnswer((_) async => right([fakeTrip(), fakeTrip(id: 6)]));
        return SearchCubit(repo);
      },
      act: (cubit) => cubit.search(
          '33.51', '36.29', '34.73', '36.71', '2026-07-15', 2),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchSucces>().having((s) => s.trips.length, 'عدد النتائج', 2),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'لا نتائج: Succes بقائمة فارغة (وليس خطأ)',
      build: () {
        when(() => repo.search(any(), any(), any(), any(), any(), any()))
            .thenAnswer((_) async => right([]));
        return SearchCubit(repo);
      },
      act: (cubit) =>
          cubit.search('33.5', '36.2', '34.7', '36.7', '2026-07-15', 1),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchSucces>().having((s) => s.trips, 'trips', isEmpty),
      ],
    );

    // كان هذا الاختبار يُثبّت وصول النصّ الإنجليزي إلى الحالة، والشاشة
    // كانت تترجمه بمطابقة يدوية على نصّ واحد فقط.
    blocTest<SearchCubit, SearchState>(
      'فشل البحث: SearchErorr برسالة عربية لا بنصّ الخادم',
      build: () {
        when(() => repo.search(any(), any(), any(), any(), any(), any()))
            .thenAnswer(
                (_) async => left(const Filuar(message: 'Search failed')));
        return SearchCubit(repo);
      },
      act: (cubit) =>
          cubit.search('33.5', '36.2', '34.7', '36.7', '2026-07-15', 1),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchErorr>()
            .having((s) => s.error, 'error', 'فشل البحث، يرجى المحاولة مرة أخرى')
            .having((s) => s.needsVerification, 'لا يحتاج توثيقاً', isFalse),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'راكب غير موثَّق: رسالة تشرح السبب وعلامة تنقله للتوثيق',
      build: () {
        when(() => repo.search(any(), any(), any(), any(), any(), any()))
            .thenAnswer((_) async => left(const Filuar(
                message: 'You must be verified as a passenger to search')));
        return SearchCubit(repo);
      },
      act: (cubit) =>
          cubit.search('33.5', '36.2', '34.7', '36.7', '2026-07-15', 1),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchErorr>()
            .having((s) => s.error, 'error',
                'يجب توثيق حسابك كراكب قبل البحث عن الرحلات')
            .having((s) => s.needsVerification, 'ينتقل للتوثيق', isTrue),
      ],
    );

    blocTest<SearchCubit, SearchState>(
      'جلسة منتهية لا تسقط إلى «فشل البحث» العام',
      build: () {
        when(() => repo.search(any(), any(), any(), any(), any(), any()))
            .thenAnswer(
                (_) async => left(const Filuar(message: 'Unauthenticated.')));
        return SearchCubit(repo);
      },
      act: (cubit) =>
          cubit.search('33.5', '36.2', '34.7', '36.7', '2026-07-15', 1),
      expect: () => [
        isA<SearchLoading>(),
        isA<SearchErorr>()
            .having((s) => s.error, 'error', HandelErorrMessage.errSession)
            .having((s) => s.needsVerification, 'ليست مسألة توثيق', isFalse),
      ],
    );
  });
}
