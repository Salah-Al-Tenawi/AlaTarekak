import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_from.dart';
import 'package:alatarekak/features/trip_create/presantion/view/trip_select_price_and_booking_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alatarekak/features/trip_create/data/repo/trip_create_repo_im.dart';
import 'package:alatarekak/features/trip_create/presantion/manger/cubit/push_ride_cubit.dart';
import 'package:dartz/dartz.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

/// طريقة الدفع في **رحلة العودة**.
///
/// رحلة العودة تُبنى على كائن `TripFrom` نفسه: يُعكس المسار ويُعاد
/// استعمال الباقي. فكل حقل لا يُعاد ضبطه يرثه من رحلة الذهاب — ومنه
/// طريقة الدفع.
///
/// المُبلَّغ عنه: ذهاب بالمحفظة وعودة نقداً، فصارت الرحلتان بالمحفظة.
class _MockCreateRepo extends Mock implements TripCreateRepoIm {}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  /// الحال بعد نشر رحلة الذهاب بالمحفظة وعكس المسار.
  TripFrom returningTrip() => TripFrom(
        startLat: '34.73',
        startLng: '36.71',
        endLat: '33.51',
        endLng: '36.29',
        startName: 'حمص',
        endName: 'دمشق',
        date: '2026-09-01 08:00:00',
        numberSeats: 3,
        price: 25000,
        distance: 160.0,
        cashType: 'e-pay',
        reverseTripRoute: true,
        numberPhone: '0999999999',
      );

  Future<void> openPriceScreen(WidgetTester tester, TripFrom trip) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => GetMaterialApp(
          getPages: [
            GetPage(
              name: RouteName.tripSelectPriceAndBookingType,
              page: () => const TripSelectPriceAndBookingType(),
            ),
            GetPage(
              name: RouteName.tripAddNumberPhone,
              page: () => const Scaffold(body: Text('شاشة الرقم')),
            ),
          ],
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    await tester.pump();

    Get.toNamed(RouteName.tripSelectPriceAndBookingType, arguments: trip);
    await tester.pumpAndSettle();
  }

  group('الشاشة تعرض ما وُرِث ثم تحفظ ما اختير', () {
    testWidgets('تبدأ على طريقة رحلة الذهاب — وهو المقصود', (tester) async {
      final trip = returningTrip();
      await openPriceScreen(tester, trip);

      expect(find.text('كاش'), findsOneWidget);
      expect(find.text('إلكتروني'), findsOneWidget);
      expect(trip.cashType, 'e-pay', reason: 'الوراثة مقصودة قبل الاختيار');
    });

    testWidgets('اختيار «كاش» يكتبه في الكائن فوراً', (tester) async {
      final trip = returningTrip();
      await openPriceScreen(tester, trip);

      await tester.tap(find.text('كاش'));
      await tester.pumpAndSettle();

      expect(trip.cashType, 'cash',
          reason: 'ما اختاره السائق لرحلة العودة هو ما يُنشر');
    });

    testWidgets('ويبقى بعد الانتقال إلى الخطوة التالية', (tester) async {
      final trip = returningTrip();
      await openPriceScreen(tester, trip);

      await tester.tap(find.text('كاش'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('التالي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(trip.cashType, 'cash');
    });

    testWidgets('والعكس كذلك: ذهاب نقداً وعودة بالمحفظة', (tester) async {
      final trip = returningTrip()..cashType = 'cash';
      await openPriceScreen(tester, trip);

      await tester.tap(find.text('إلكتروني'));
      await tester.pumpAndSettle();

      expect(trip.cashType, 'e-pay');
    });
  });

  group('ما يصل الخادم فعلاً', () {
    test('العودة نقداً تُرسَل «cash» لا طريقة رحلة الذهاب', () async {
      final repo = _MockCreateRepo();
      final captured = <String>[];

      when(() => repo.createTrip(any(), any(), any(), any(), any(), any(),
              any(), any(), any(), any(), any(), any()))
          .thenAnswer((invocation) async {
        // الوسيط العاشر هو طريقة الدفع
        captured.add(invocation.positionalArguments[9] as String);
        return right(fakeTrip());
      });

      // ما تخرج به شاشة الدفع بعد اختيار «كاش» لرحلة العودة
      final trip = returningTrip()..cashType = 'cash';

      final cubit = PushRideCubit(repo);
      addTearDown(cubit.close);
      await cubit.pushRide(trip);

      expect(captured.single, 'cash',
          reason: 'العميل يرسل ما اختاره السائق — فإن نُشرت بالمحفظة '
              'فالقرار عند الخادم');
    });

    test('والذهاب بالمحفظة تُرسَل «e-pay»', () async {
      final repo = _MockCreateRepo();
      final captured = <String>[];

      when(() => repo.createTrip(any(), any(), any(), any(), any(), any(),
              any(), any(), any(), any(), any(), any()))
          .thenAnswer((invocation) async {
        captured.add(invocation.positionalArguments[9] as String);
        return right(fakeTrip());
      });

      final cubit = PushRideCubit(repo);
      addTearDown(cubit.close);
      await cubit.pushRide(returningTrip());

      expect(captured.single, 'e-pay');
    });
  });
}
