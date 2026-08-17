import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/maps/data/model/map_info_model.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
import 'package:alatarekak/features/maps/presantion/manger/cubit/trip_details_map_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class MockMapRepo extends Mock implements MapRepoIm {}

/// خدمتا المسار (GraphHopper و OpenRouteService) خارجيّتان، وأخطاؤهما
/// إنجليزية دائماً ولا يمسّها مستند مواصفات الباك-إند. وكانت
/// [route_map_view] تعرضها حرفياً بصيغة «خطأ: {رسالة الخدمة}».

void main() {
  late MockMapRepo repo;
  final start = const LatLng(33.5, 36.3);
  final end = const LatLng(33.6, 36.4);

  setUpAll(() {
    registerFallbackValue(const LatLng(0, 0));
  });

  setUp(() {
    repo = MockMapRepo();
  });

  void stub(Either<Filuar, List<RouteModel>> result) {
    when(() => repo.fetchRouteBYgraphHopper(any(), any()))
        .thenAnswer((_) async => result);
    when(() => repo.fetchRouteBYOpenRouteServices(any(), any()))
        .thenAnswer((_) async => result);
  }

  group('TripDetailsMapCubit — تعذّر حساب المسار', () {
    blocTest<TripDetailsMapCubit, TripDetailsMapState>(
      'خطأ الخدمة الخارجية يُعرَّب ولا يُعرض بنصّه',
      build: () {
        stub(left(const Filuar(
            message: 'Failed to get route options from provider')));
        return TripDetailsMapCubit(repo);
      },
      act: (cubit) => cubit.fetchRouteByIndex(start, end, 0),
      expect: () => [
        isA<TripDetailsMapLoading>(),
        isA<TripDetailsMapError>()
            .having((s) => s.message, 'message', 'تعذر حساب المسار، حاول مجدداً')
            .having((s) => s.message, 'بلا إنجليزية',
                isNot(contains('route options'))),
      ],
    );

    blocTest<TripDetailsMapCubit, TripDetailsMapState>(
      'أي عطل آخر يسقط إلى رسالة المسار لا إلى العامة',
      build: () {
        stub(left(const Filuar(message: 'Rate limit exceeded by provider')));
        return TripDetailsMapCubit(repo);
      },
      act: (cubit) => cubit.fetchRouteByIndex(start, end, 1),
      expect: () => [
        isA<TripDetailsMapLoading>(),
        isA<TripDetailsMapError>()
            .having((s) => s.message, 'message', 'تعذر حساب المسار، حاول مجدداً')
            .having((s) => s.message, 'ليست العامة',
                isNot(HandelErorrMessage.errServer)),
      ],
    );

    blocTest<TripDetailsMapCubit, TripDetailsMapState>(
      'انقطاع الشبكة يصل بالعربية أصلاً فلا يتغيّر معناه',
      build: () {
        // handelDioExcptions يترجم انقطاع الشبكة عربياً قبل الوصول هنا
        stub(left(const Filuar(message: 'تحقق من اتصال الإنترنت')));
        return TripDetailsMapCubit(repo);
      },
      act: (cubit) => cubit.fetchRouteByIndex(start, end, 0),
      expect: () => [
        isA<TripDetailsMapLoading>(),
        isA<TripDetailsMapError>().having(
            (s) => s.message, 'message', 'تعذر حساب المسار، حاول مجدداً'),
      ],
    );
  });
}
