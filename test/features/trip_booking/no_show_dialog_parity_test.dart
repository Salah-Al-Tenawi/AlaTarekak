import 'dart:io';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/core/utils/widgets/app_dialog.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/manger/cubit/booking_user_in_trip_cubit.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/view/booking_user_in_trip.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_details_sheet.dart';
import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockBookingMeRepo extends Mock implements BookingMeRepo {}

class MockChatRepo extends Mock implements ChatRepo {}

class MockDriverCubit extends MockCubit<BookingUserInTripState>
    implements BookingUserInTripCubit {}

/// حوارا بلاغ الغياب — **واحد لا اثنان**.
///
/// الإجراء نفسه من الطرفين: أحدهما يبلّغ عن غياب الآخر، وللمُبلَّغ عنه
/// ساعتان للاعتراض. وكان جانب السائق يستعمل حوار التطبيق المشترك بينما
/// بقي جانب الراكب على `AlertDialog` مبنيّ يدوياً بعنوان «تأكيد» وزرَّي
/// «لا»/«نعم» بمقاس ثابت — فبدا الإجراء الواحد إجراءين.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('no_show_parity');
    Hive.init(tempDir.path);
    await Hive.openBox<String>(HiveBoxes.cacheBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } on FileSystemException {
      // قفل ملفات مؤقت على ويندوز — غير مؤثر
    }
  });

  setUp(() => Get.testMode = true);

  Widget wrap(Widget child) => ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(body: child),
          ),
        ),
      );

  /// جانب الراكب: يفتح ورقة تفاصيل حجز انطلقت رحلته منذ ساعتين.
  Future<void> pumpPassenger(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final cubit = BookingMeCubit(MockBookingMeRepo(), chatRepo: MockChatRepo());
    addTearDown(cubit.close);

    await tester.pumpWidget(wrap(
      BlocProvider<BookingMeCubit>.value(
        value: cubit,
        child: BookingDetailsContent(
          booking: fakeBooking(departsIn: const Duration(hours: -2)),
        ),
      ),
    ));
    await tester.pump();

    await tester.tap(find.text('لم يحضر'));
    await tester.pumpAndSettle();
  }

  /// جانب السائق: شاشة حجوزات الرحلة برحلة انطلقت منذ ساعتين.
  ///
  /// تُفتح بمسارها كما تُفتح في التطبيق — البطاقة داخلية لا تُبنى وحدها.
  Future<void> pumpDriver(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // سقّالة المعاينة تعبّئ حجوزات وهمية فوق ما نمرّره
    kPreviewSampleBookings = false;

    final cubit = MockDriverCubit();
    whenListen(
      cubit,
      const Stream<BookingUserInTripState>.empty(),
      initialState: BookingUserInTripInitial(),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          initialRoute: '/bookings',
          getPages: [
            GetPage(
              name: '/bookings',
              page: () => BlocProvider<BookingUserInTripCubit>.value(
                value: cubit,
                child: const BookingUserINTrip(),
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
    Get.offAllNamed('/bookings', arguments: {
      'bookings': [
        BookingModel(
          id: 9,
          userName: 'أحمد',
          userId: 3,
          avatar: null,
          rating: 4.5,
          seats: 1,
          status: 'confirmed',
          totaPrice: 25000,
          bookingat: DateTime.now().toIso8601String(),
          numberPhone: '0999999999',
        ),
      ],
      'departure': DateTime.now().subtract(const Duration(hours: 2)),
    });
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(find.text('لم يحضر'));
    await tester.pumpAndSettle();
  }

  group('الطرفان يريان الحوار نفسه', () {
    testWidgets('جانب الراكب يستعمل حوار التطبيق', (tester) async {
      await pumpPassenger(tester);

      expect(find.byType(AppDialogContent), findsOneWidget);
      expect(find.text('تأكيد'), findsNothing,
          reason: 'العنوان العامّ القديم لم يعد موجوداً');
    });

    testWidgets('وجانب السائق كذلك', (tester) async {
      await pumpDriver(tester);

      expect(find.byType(AppDialogContent), findsOneWidget);
    });

    testWidgets('العنوان يسمّي الطرف المعنيّ في الحالين', (tester) async {
      await pumpPassenger(tester);
      expect(find.text('السائق لم يحضر؟'), findsOneWidget);
    });

    testWidgets('وعنوان السائق مقابله', (tester) async {
      await pumpDriver(tester);
      expect(find.text('الراكب لم يحضر؟'), findsOneWidget);
    });
  });

  group('الأزرار مسمّاة بالإجراء لا بـ«نعم»/«لا»', () {
    testWidgets('جانب الراكب', (tester) async {
      await pumpPassenger(tester);

      expect(find.text('تسجيل البلاغ'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
      expect(find.text('نعم'), findsNothing);
      expect(find.text('لا'), findsNothing);
    });

    testWidgets('جانب السائق', (tester) async {
      await pumpDriver(tester);

      expect(find.text('تسجيل البلاغ'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
    });
  });

  group('النصّ يقول العواقب نفسها للطرفين', () {
    testWidgets('مهلة الاعتراض ونقاط الثقة — جانب الراكب', (tester) async {
      await pumpPassenger(tester);

      expect(find.textContaining('ساعتان للاعتراض'), findsOneWidget);
      expect(find.textContaining('نقاط ثقته'), findsOneWidget);
      expect(find.textContaining('لا تُرسله إلا بعد انتظاره'), findsOneWidget);
    });

    testWidgets('ونفسها — جانب السائق', (tester) async {
      await pumpDriver(tester);

      expect(find.textContaining('ساعتان للاعتراض'), findsOneWidget);
      expect(find.textContaining('نقاط ثقته'), findsOneWidget);
      expect(find.textContaining('لا تُرسله إلا بعد انتظاره'), findsOneWidget);
    });

    testWidgets('واسم من يُبلَّغ عنه مذكور — جانب الراكب', (tester) async {
      await pumpPassenger(tester);

      // fakeBooking سائقها «أحمد»
      expect(find.textContaining('بحقّ أحمد'), findsOneWidget);
    });
  });
}
