import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/data/repo/trip_me_repo_im.dart';
import 'package:alatarekak/features/trip_me/presantion/manger/cubit/trip_me_cubit.dart';
import 'package:alatarekak/features/trip_me/presantion/view/trip_me_list.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockTripMeRepo extends Mock implements TripMeRepoIm {}

/// كم مرة تُطلب «رحلاتي» من الخادم؟
///
/// الشاشة كانت تطلبها من **داخل البناء**: الفرع الأخير في `builder`
/// يجدول `getMeTrips()` في `addPostFrameCallback` ويعيد `SizedBox`.
/// وذلك الفرع يلتقط كل حالة لا فرع لها — ومنها `TripMeCancel` — فتقع
/// طلبات لا يقصدها أحد، ويتضاعف الطلب بعد كل إلغاء لأن `cancelTrip`
/// تستدعي `getMeTrips()` بنفسها أيضاً.

TripModel _trip(int id) => TripModel.fromMap({
      'id': id,
      'driver_id': 1001,
      'pickup_address': 'دمشق',
      'destination_address': 'حمص',
      'pickup_location': {'lat': 33.5, 'lng': 36.3},
      'destination_location': {'lat': 34.7, 'lng': 36.7},
      'distance': 162117,
      'duration': 6144,
      'departure_time': '2026-08-20T16:00:00.000000Z',
      'available_seats': 2,
      'price_per_seat': '25000.00',
      'vehicle_type': 'crolla',
      'payment_method': 'cash',
      'booking_type': 'direct',
      'status': 'active',
      'communication_number': '+963988626577',
      'created_at': '2026-08-18T08:00:00.000000Z',
      'bookings_count': 0,
    });

void main() {
  late MockTripMeRepo repo;
  late Directory tempDir;

  setUp(() async {
    repo = MockTripMeRepo();
    Get.testMode = true;

    tempDir = await Directory.systemTemp.createTemp('trip_me_fetch');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: 1001,
        firstName: 'يزن',
        lastName: 'صلاح',
        email: 'me@example.com',
        accessToken: 'a',
        refreshToken: 'r',
      ),
    );
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  Future<TripMeCubit> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = TripMeCubit(repo);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<TripMeCubit>.value(
              value: cubit,
              child: const TripMeList(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return cubit;
  }

  group('فتح الشاشة', () {
    testWidgets('تُطلب الرحلات مرة واحدة لا أكثر', (tester) async {
      when(() => repo.showAllTrip())
          .thenAnswer((_) async => right([_trip(1), _trip(2)]));

      await pump(tester);
      await tester.pump(const Duration(milliseconds: 800));

      verify(() => repo.showAllTrip()).called(1);
    });

    testWidgets('إعادة البناء لا تُطلق طلباً جديداً', (tester) async {
      when(() => repo.showAllTrip())
          .thenAnswer((_) async => right([_trip(1)]));

      await pump(tester);
      await tester.pump(const Duration(milliseconds: 800));
      // عدة إطارات إضافية — لا شيء يستدعي طلباً جديداً
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      verify(() => repo.showAllTrip()).called(1);
    });

    testWidgets('فشل الجلب يعرض الخطأ ولا يعيد الطلب تلقائياً',
        (tester) async {
      when(() => repo.showAllTrip())
          .thenAnswer((_) async => left(const Filuar(message: 'Server error')));

      await pump(tester);
      await tester.pump(const Duration(milliseconds: 800));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      verify(() => repo.showAllTrip()).called(1);
    });
  });

  group('بعد إلغاء رحلة', () {
    testWidgets('تُعاد القائمة مرة واحدة لا مرتين', (tester) async {
      when(() => repo.showAllTrip())
          .thenAnswer((_) async => right([_trip(1)]));
      when(() => repo.cancelTrip(any())).thenAnswer((_) async => right(unit));

      final cubit = await pump(tester);
      await tester.pump(const Duration(milliseconds: 800));
      clearInteractions(repo);

      await cubit.cancelTrip(1);
      await tester.pump(const Duration(milliseconds: 800));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      verify(() => repo.showAllTrip()).called(1);
    });
  });

  group('الشاشة كاملة بحمولة الإنتاج (8 رحلات)', () {
    testWidgets('تُرسم بلا استثناء', (tester) async {
      final trips = [
        _trip(538), _trip(537), _trip(535), _trip(530),
        _trip(536), _trip(529), _trip(528), _trip(527),
      ];
      when(() => repo.showAllTrip()).thenAnswer((_) async => right(trips));

      await pump(tester);
      await tester.pump(const Duration(milliseconds: 1500));

      expect(tester.takeException(), isNull);
      expect(find.text('رحلاتي'), findsOneWidget);
    });

  });

  group('حالة بلا فرع خاص', () {
    // `TripMeOneLoaded` (من showOneTrip) لا فرع لها في البناء. كانت
    // تسقط في الفرع الأخير الذي يجدول `getMeTrips()` — فيقع طلب شبكة
    // لا يقصده أحد لمجرّد أن الكيوبت أصدر حالة لا تعني القائمة.
    testWidgets('لا تُطلق طلب شبكة من داخل البناء', (tester) async {
      when(() => repo.showAllTrip())
          .thenAnswer((_) async => right([_trip(1)]));
      when(() => repo.showOneTrip(any()))
          .thenAnswer((_) async => right(_trip(5)));

      final cubit = await pump(tester);
      await tester.pump(const Duration(milliseconds: 800));
      clearInteractions(repo);

      await cubit.showOneTrip(5);
      await tester.pump(const Duration(milliseconds: 800));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 120));
      }

      verifyNever(() => repo.showAllTrip());
    });
  });

  group('العودة إلى التبويب', () {
    // الكيوبت يعيش فوق الـ PageView فينجو، والشاشة تُبنى من جديد في كل
    // عودة. بلا شرط لوقع طلب عند كل ضغطة على «رحلاتي».
    testWidgets('لا تُعاد الرحلات ما دامت محمّلة', (tester) async {
      when(() => repo.showAllTrip())
          .thenAnswer((_) async => right([_trip(1), _trip(2)]));

      final cubit = TripMeCubit(repo);
      addTearDown(cubit.close);

      Widget app() => ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: BlocProvider<TripMeCubit>.value(
                  value: cubit,
                  child: const TripMeList(),
                ),
              ),
            ),
          );

      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 800));
      verify(() => repo.showAllTrip()).called(1);

      // غادر التبويب ثم عُد — الشاشة تُبنى من جديد والكيوبت باقٍ
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 800));

      verifyNever(() => repo.showAllTrip());
    });
  });

  group('بقياس هواوي Y9 2019 داخل بنية الرئيسية', () {
    // 1080×2340 بكثافة 2.5 ← نحو 432×936 منطقية. والشاشة تعيش داخل
    // PageView مغلَّف بـ FadeTransition كما في home.dart — نُعيد البنية
    // نفسها لأن تركيبها قد يختلف عن عرض الشاشة وحدها.
    testWidgets('تُرسم وتستقرّ بلا تعليق', (tester) async {
      final trips = List.generate(8, (i) => _trip(530 + i));
      when(() => repo.showAllTrip()).thenAnswer((_) async => right(trips));

      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cubit = TripMeCubit(repo);
      addTearDown(cubit.close);
      final controller = PageController(initialPage: 1);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          child: MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: BlocProvider<TripMeCubit>.value(
                value: cubit,
                child: PageView(
                  controller: controller,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    Scaffold(body: Text('تبويب آخر')),
                    TripMeList(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // pumpAndSettle يعلّق لو بقيت الشاشة تُعيد الرسم بلا استقرار —
      // وهو ما يبدو للمستخدم تجمّداً
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
