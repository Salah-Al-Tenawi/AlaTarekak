import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/trip_details/data/repo/trip_details_repo.dart';
import 'package:alatarekak/features/trip_details/presantaion/manger/cubit/tripdetails_cubit.dart';
import 'package:alatarekak/features/trip_details/presantaion/view/trip_details.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

/// شاشة تفاصيل الرحلة تُمحى بلا سبب.
///
/// الكيوبت يُصدر حالات ليست شاشات — `GoToProfile` و`GoToChat`
/// و`FinishTrip` و`RequestBooking` — إشارات للمستمع لا محتوى. وكان
/// البنّاء يُستدعى لها جميعاً فتسقط في فرعه الأخير، فتختفي الرحلة ويبقى
/// **زرّ «أعد المحاولة» وحده على شاشة فارغة، بلا خطأ ولا سبب**.
///
/// يكفي أن يفتح المستخدم ملف السائق ثم يعود.

class MockTripDetailsRepo extends Mock implements TripDetailsRepoIM {}

const int _myUserId = 1;
const int _tripId = 5;
const int _driverId = 3;

void main() {
  late MockTripDetailsRepo repo;
  late Directory tempDir;

  setUpAll(() async {
    // fetchTrip يقرأ myid() من صندوق الجلسة
    tempDir = await Directory.systemTemp.createTemp('trip_details_screen');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: _myUserId,
        firstName: 'يزن',
        lastName: 'صلاح',
        email: 'me@example.com',
        accessToken: 't',
        refreshToken: 'r',
      ),
    );
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // قفل ملفات مؤقت على ويندوز — غير مؤثر
    }
  });

  setUp(() {
    repo = MockTripDetailsRepo();
    when(() => repo.featchTrip(_tripId))
        .thenAnswer((_) async => right(fakeTrip(id: _tripId, driverId: _driverId)));
  });

  tearDown(Get.reset);

  /// يفتح الشاشة عبر `Get.to` لأن `initState` يقرأ `Get.arguments`.
  Future<TripDetailsCubit> openScreen(WidgetTester tester) async {
    final cubit = TripDetailsCubit(tripDetailsRepoIM: repo);
    addTearDown(cubit.close);

    // قياس هاتف حقيقي: السطح الافتراضي 800×600 مع designSize 390 يكبّر
    // كل شيء فتفيض صفوف البطاقة — عيب في المقياس لا في الشاشة
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => GetMaterialApp(
          theme: ThemApp.lightThem,
          getPages: [
            GetPage(
              name: RouteName.profile,
              page: () => const Scaffold(body: Text('ملف السائق')),
            ),
          ],
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Get.to(
                  () => BlocProvider.value(
                    value: cubit,
                    child: const TripDetails(),
                  ),
                  arguments: _tripId,
                ),
                child: const Text('افتح الرحلة'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح الرحلة'));
    await tester.pumpAndSettle();
    return cubit;
  }

  /// نصّ من جسم الرحلة — وجوده يعني أن المحتوى ما زال معروضاً.
  final tripContent = find.text('دمشق');
  final loneRetry = find.text('أعد المحاولة');

  group('الرحلة تُعرض أولاً', () {
    testWidgets('بعد الجلب يظهر محتوى الرحلة', (tester) async {
      await openScreen(tester);

      expect(tripContent, findsWidgets);
      expect(loneRetry, findsNothing);
    });
  });

  group('حالات ليست شاشات لا تمحو المعروض', () {
    testWidgets('طلب فتح محادثة مع السائق: الرحلة تبقى', (tester) async {
      final cubit = await openScreen(tester);

      // يُصدر TripDetailsGoToChat — إشارة للمستمع لا شاشة
      cubit.gotoChatWithDriver(_driverId, name: 'أحمد');
      // نبضتان لا واحدة: الأولى تُسلّم الحالة وتجدول البناء، والثانية
      // تبنيه. بنبضة واحدة يبقى المعروض القديم فيمرّ الاختبار على كودٍ
      // معطوب — تحقّقنا من ذلك بنزع الحارس.
      await tester.pump();
      await tester.pump();

      expect(tripContent, findsWidgets,
          reason: 'الرحلة اختفت لمجرد إصدار حالة تنقّل');
      expect(loneRetry, findsNothing);
    });

    testWidgets('فتح ملف السائق ثم العودة: الرحلة ما زالت معروضة',
        (tester) async {
      final cubit = await openScreen(tester);

      cubit.fetchProfile(_driverId);
      await tester.pumpAndSettle();
      expect(find.text('ملف السائق'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      expect(tripContent, findsWidgets,
          reason: 'هذا هو المسار الذي يراه المستخدم: يعود فيجد شاشة فارغة');
      expect(loneRetry, findsNothing);
    });
  });

  group('حالات العرض ما زالت تعمل', () {
    testWidgets('الخطأ يُعرض برسالته وزرّ إعادة المحاولة', (tester) async {
      final cubit = await openScreen(tester);

      when(() => repo.featchTrip(_tripId))
          .thenAnswer((_) async => left(const Filuar(message: 'Unauthenticated')));
      await cubit.fetchTrip(_tripId);
      await tester.pumpAndSettle();

      expect(loneRetry, findsOneWidget, reason: 'هنا الزرّ في محلّه');
      expect(tripContent, findsNothing);
    });
  });
}
