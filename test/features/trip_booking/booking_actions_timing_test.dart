import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingMeRepo extends Mock implements BookingMeRepo {}

class MockChatRepo extends Mock implements ChatRepo {}

/// أزرار بطاقة «حجوزاتي» عبر الزمن.
///
/// ثلاث مراحل بحسب المتطلبات المحدَّثة (2026-08-18):
///   قبل الانطلاق          → إلغاء الحجز
///   مع الانطلاق           → تأكيد الوصول
///   بعد ساعة من الانطلاق  → يُضاف بلاغ «السائق لم يحضر»
///
/// كان البلاغ يظهر مع الانطلاق مباشرة — وسائق تأخّر عشر دقائق ليس
/// سائقاً غائباً، والبلاغ يخصم من نقاط ثقته.

BookingMe _booking({
  required Duration fromNow,
  String status = 'confirmed',
}) =>
    BookingMe(
      bookingId: 10,
      status: status,
      seats: 2,
      totalPrice: 50000,
      bookingDate: DateTime.now().subtract(const Duration(days: 1)),
      passengerCommunicationNumber: '0999999999',
      driverCommunicationNumber: '0988888888',
      rideId: 5,
      pickupAddress: 'دمشق',
      destinationAddress: 'حمص',
      departureTime: DateTime.now().add(fromNow),
      distanceKm: 160,
      durationMinutes: 120,
      pricePerSeat: 25000,
      paymentMethod: 'wallet',
      vehicleType: 'sedan',
      rideStatus: 'active',
      driverName: 'أحمد',
      driverRating: 4.5,
      driverAvatar: '',
      userDriver: 3,
    );

void main() {
  late MockBookingMeRepo repo;
  late MockChatRepo chatRepo;
  late BookingMeCubit cubit;

  setUp(() {
    repo = MockBookingMeRepo();
    chatRepo = MockChatRepo();
    Get.testMode = true;
    cubit = BookingMeCubit(repo, chatRepo: chatRepo);
  });

  tearDown(() => cubit.close());

  Future<void> pump(WidgetTester tester, BookingMe booking) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        child: GetMaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: BlocProvider<BookingMeCubit>.value(
              value: cubit,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: BookingItem(
                    booking: booking,
                    onTapDetails: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('قبل الانطلاق', () {
    testWidgets('إلغاء الحجز وحده — لا تأكيد ولا بلاغ', (tester) async {
      await pump(tester, _booking(fromNow: const Duration(hours: 3)));

      expect(find.text('إلغاء الحجز'), findsOneWidget);
      expect(find.text('تأكيد الوصول'), findsNothing);
      expect(find.text('لم يحضر'), findsNothing);
    });
  });

  group('مع الانطلاق', () {
    testWidgets('تأكيد الوصول يظهر، والبلاغ لا', (tester) async {
      await pump(tester, _booking(fromNow: const Duration(minutes: -5)));

      expect(find.text('تأكيد الوصول'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing,
          reason: 'من انطلق قبل خمس دقائق ليس غائباً');
    });

    testWidgets('بعد خمسين دقيقة: ما زال البلاغ مغلقاً', (tester) async {
      await pump(tester, _booking(fromNow: const Duration(minutes: -50)));

      expect(find.text('تأكيد الوصول'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing);
    });
  });

  group('بعد ساعة من الانطلاق', () {
    testWidgets('التأكيد والبلاغ معاً', (tester) async {
      await pump(
          tester, _booking(fromNow: const Duration(hours: -1, minutes: -10)));

      expect(find.text('تأكيد الوصول'), findsOneWidget);
      expect(find.text('لم يحضر'), findsOneWidget);
    });
  });

  group('حالات لا إجراء فيها', () {
    testWidgets('طلب معلّق: إلغاء الطلب مهما كان الوقت', (tester) async {
      await pump(
        tester,
        _booking(fromNow: const Duration(hours: -3), status: 'pending'),
      );

      expect(find.text('إلغاء الطلب'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing);
    });

    testWidgets('حجز ملغى: لا تأكيد ولا بلاغ', (tester) async {
      await pump(
        tester,
        _booking(fromNow: const Duration(hours: -3), status: 'cancelled'),
      );

      expect(find.text('الحجز ملغى'), findsOneWidget);
      expect(find.text('لم يحضر'), findsNothing);
    });
  });
}
