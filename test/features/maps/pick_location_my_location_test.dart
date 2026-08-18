import 'package:alatarekak/core/service/location_service.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/core/utils/widgets/my_location_button.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
import 'package:alatarekak/features/maps/presantion/manger/pick_location/cubit/pick_location_cubit.dart';
import 'package:alatarekak/features/maps/presantion/view/pick_location.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class MockMapRepo extends Mock implements MapRepoIm {}

/// «موقعي» في شاشة اختيار النقطة — وهي الشاشة التي يفتحها البحث فعلاً.
///
/// أُضيف الزرّ أولاً إلى `SearchRideMap` وهي خريطة أخرى لا يمرّ بها
/// البحث، فلم يظهر للمستخدم. والبحث يفتح `PickLocation` مرّة للانطلاق
/// ومرّة للوجهة — فالموقع يقع على واحدة منهما لا عليهما معاً.

const _damascus = LatLng(33.5138, 36.2765);

Future<void> _pump(WidgetTester tester, {required String type}) async {
  final repo = MockMapRepo();
  when(() => repo.getPlaceName(any()))
      .thenAnswer((_) async => right('دمشق، سوريا'));

  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => GetMaterialApp(
        theme: ThemApp.lightThem,
        initialRoute: '/pick',
        getPages: [
          GetPage(
            name: '/pick',
            page: () => BlocProvider(
              create: (_) => PickLocationCubit(repo),
              child: const PickLocation(),
            ),
          ),
        ],
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    ),
  );
  await tester.pump();
  Get.offAllNamed('/pick', arguments: {'type': type});
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => registerFallbackValue(_damascus));
  tearDown(() {
    LocationService.debugOverride = null;
    Get.reset();
  });

  group('الزرّ موجود في شاشة اختيار النقطة', () {
    testWidgets('عند تحديد الانطلاق: «انطلق من موقعي»', (tester) async {
      await _pump(tester, type: 'source');

      expect(find.byType(MyLocationButton), findsOneWidget);
      expect(find.text('انطلق من موقعي'), findsOneWidget);
    });

    testWidgets('عند تحديد الوجهة: «وجهتي هنا»', (tester) async {
      await _pump(tester, type: 'destination');

      expect(find.text('وجهتي هنا'), findsOneWidget);
      expect(find.text('انطلق من موقعي'), findsNothing);
    });
  });

  group('لكل فتحة نقطة واحدة', () {
    testWidgets('تحديد الموقع يضع النقطة المطلوبة وحدها', (tester) async {
      LocationService.debugOverride =
          () async => const LocationSuccess(_damascus);

      await _pump(tester, type: 'source');
      await tester.tap(find.text('انطلق من موقعي'));
      await tester.pumpAndSettle();

      // الشاشة تعيد نقطة واحدة إلى مستدعيها، والوجهة تُختار بفتحة أخرى
      expect(find.text('دمشق، سوريا'), findsOneWidget);
      expect(find.text('وجهتي هنا'), findsNothing);
    });
  });

  group('التعذّر', () {
    testWidgets('لا نقطة تُوضع ويُشرح السبب', (tester) async {
      LocationService.debugOverride =
          () async => const LocationDenied(LocationFailure.outsideSyria);

      await _pump(tester, type: 'source');
      await tester.tap(find.text('انطلق من موقعي'));
      await tester.pumpAndSettle();

      expect(find.textContaining('خارج سوريا'), findsOneWidget);
      expect(find.text('دمشق، سوريا'), findsNothing);
    });
  });
}
