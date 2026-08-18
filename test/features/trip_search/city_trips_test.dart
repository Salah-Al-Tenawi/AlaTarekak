import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_search/data/repo/search_repo_im.dart';
import 'package:alatarekak/features/trip_search/presantion/manger/cubit/search_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockSearchRepo extends Mock implements SearchRepoIm {}

/// «رحلات مدينتي» — `GET /rides/city-trips`.
///
/// الضغط على «بحث» بلا إدخال شيء لم يعد خطأً يستحقّ ثلاث رسائل تطالب
/// بملء الحقول: الخادم يقرأ مدينة المستخدم من عنوان حسابه ويعيد ما
/// ينطلق منها أو يتّجه إليها.

void main() {
  late MockSearchRepo repo;
  late SearchCubit cubit;

  setUp(() {
    repo = MockSearchRepo();
    cubit = SearchCubit(repo);
  });

  tearDown(() => cubit.close());

  test('المسار كما أرسله الباك إند', () {
    expect(ApiEndPoint.cityTrips, endsWith('/rides/city-trips'));
  });

  group('النجاح', () {
    test('التحميل ثم النتائج موسومةً بمصدرها', () async {
      final trips = [fakeTrip(id: 1), fakeTrip(id: 2)];
      when(() => repo.cityTrips()).thenAnswer((_) async => right(trips));

      final seen = <SearchState>[];
      cubit.stream.listen(seen.add);
      await cubit.searchMyCity();
      await Future<void>.delayed(Duration.zero);

      expect(seen.first, isA<SearchLoading>());
      final last = seen.last as SearchSucces;
      expect(last.trips, hasLength(2));
      expect(
        last.fromCity,
        isTrue,
        reason: 'الشاشة تعتمد عليه لتُبدّل العنوان ونصّ القائمة الفارغة',
      );
    });

    test('قائمة فارغة نجاحٌ لا خطأ', () async {
      when(() => repo.cityTrips())
          .thenAnswer((_) async => right(<TripModel>[]));

      await cubit.searchMyCity();

      final state = cubit.state as SearchSucces;
      expect(state.trips, isEmpty);
      expect(state.fromCity, isTrue);
    });
  });

  group('الفشل', () {
    test('الرسالة تصل معرَّبة لا بنصّ الخادم', () async {
      when(() => repo.cityTrips()).thenAnswer(
          (_) async => left(const Filuar(message: 'Unauthenticated')));

      await cubit.searchMyCity();

      final state = cubit.state as SearchErorr;
      expect(state.error, isNot(contains('Unauthenticated')));
      expect(state.error, isNotEmpty);
    });

    test('راكب غير موثَّق يُوسَم فتنقله الشاشة إلى التوثيق', () async {
      when(() => repo.cityTrips()).thenAnswer((_) async =>
          left(const Filuar(message: 'You must be verified as a passenger')));

      await cubit.searchMyCity();

      expect((cubit.state as SearchErorr).needsVerification, isTrue);
    });
  });

  group('البحث بمعايير لا يُوسَم بالمدينة', () {
    test('نتائج البحث العادي fromCity = false', () async {
      when(() => repo.search(any(), any(), any(), any(), any(), any()))
          .thenAnswer((_) async => right([fakeTrip(id: 3)]));

      await cubit.search('1', '2', '3', '4', '2026-09-01', 2);

      expect((cubit.state as SearchSucces).fromCity, isFalse);
    });
  });
}
