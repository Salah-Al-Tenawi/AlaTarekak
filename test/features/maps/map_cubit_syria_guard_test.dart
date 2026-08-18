import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
import 'package:alatarekak/features/maps/presantion/manger/push_ride_map/map_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class MockMapRepo extends Mock implements MapRepoIm {}

/// حصر نقاط إنشاء الرحلة داخل سوريا.
///
/// كان السائق يستطيع وضع نقطته في بيروت أو بغداد، فيُكمل المعالج كلّه —
/// المسار والموعد والمقاعد والسعر — ثم يرفض الخادم الرحلة.

const _damascus = LatLng(33.5138, 36.2765);
const _aleppo = LatLng(36.2021, 37.1343);
const _beirut = LatLng(33.8938, 35.5018);
const _baghdad = LatLng(33.3152, 44.3661);

void main() {
  late MockMapRepo repo;
  late MapCubit cubit;

  setUpAll(() {
    registerFallbackValue(_damascus);
  });

  setUp(() {
    repo = MockMapRepo();
    when(() => repo.getPlaceName(any()))
        .thenAnswer((_) async => right('مكان'));
    when(() => repo.fetchRouteBYOpenRouteServices(any(), any()))
        .thenAnswer((_) async => left(const Filuar(message: 'no route')));
    when(() => repo.fetchRouteBYgraphHopper(any(), any()))
        .thenAnswer((_) async => left(const Filuar(message: 'no route')));
    cubit = MapCubit(repo);
  });

  tearDown(() => cubit.close());

  group('النقر على الخريطة', () {
    test('نقطة داخل سوريا تُقبل وتصير نقطة مقترحة', () {
      expect(cubit.tapOnMap(_damascus), isTrue);
      expect(cubit.pendingPoint, _damascus);
    });

    test('نقطة في بيروت تُرفض ولا تُثبَّت', () {
      expect(cubit.tapOnMap(_beirut), isFalse);
      expect(cubit.pendingPoint, isNull);
    });

    test('نقطة في بغداد تُرفض', () {
      expect(cubit.tapOnMap(_baghdad), isFalse);
      expect(cubit.pendingPoint, isNull);
    });

    test('الرفض لا يمسح نقطة مقترحة صالحة سبقته', () {
      cubit.tapOnMap(_damascus);
      cubit.tapOnMap(_beirut);

      expect(cubit.pendingPoint, _damascus,
          reason: 'لمسة خاطئة لا تُلغي اختياراً صحيحاً');
    });
  });

  group('التثبيت بعد النقر', () {
    test('نقطة الانطلاق تُثبَّت داخل سوريا', () {
      cubit.tapOnMap(_damascus);
      cubit.confirmPending();

      expect(cubit.startLocation, _damascus);
    });

    test('الوجهة كذلك', () {
      cubit.tapOnMap(_damascus);
      cubit.confirmPending();
      cubit.setSearchMode(false);
      cubit.tapOnMap(_aleppo);
      cubit.confirmPending();

      expect(cubit.endLocation, _aleppo);
    });
  });

  group('الاختيار من نتائج البحث', () {
    PlaceSuggestion place(LatLng at) => PlaceSuggestion(
          displayName: 'مكان ما',
          lat: at.latitude,
          lng: at.longitude,
        );

    test('نتيجة داخل سوريا تُقبل', () {
      expect(cubit.selectFromSearch(place(_damascus)), isTrue);
      expect(cubit.startLocation, _damascus);
    });

    test('نتيجة خارجها تُرفض ولا تُغيّر شيئاً', () {
      expect(cubit.selectFromSearch(place(_beirut)), isFalse);
      expect(cubit.startLocation, isNull);
    });
  });
}
