import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/data/repo/booking_me_repo.dart';
import 'package:alatarekak/features/trip_booking/presantion/manger/cubit/booking_me_cubit.dart';
import 'package:alatarekak/features/trip_booking/presantion/view/widget/booking_item.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockBookingMeRepo extends Mock implements BookingMeRepo {}

class MockChatRepo extends Mock implements ChatRepo {}

/// أيقونة مراسلة السائق في بطاقة «حجوزاتي».
///
/// سياسة التطبيق: لا محادثة بلا حجز. وكان الراكب الطرف الوحيد بلا طريق
/// إليها من قائمة حجوزاته — للسائق زرّ مراسلة في شاشة حجوزات رحلته،
/// وللراكب لا شيء.

BookingMe _booking({String status = 'confirmed'}) => BookingMe(
      bookingId: 10,
      status: status,
      seats: 2,
      totalPrice: 50000,
      bookingDate: DateTime(2026, 7, 1),
      passengerCommunicationNumber: '0999999999',
      driverCommunicationNumber: '0988888888',
      rideId: 5,
      pickupAddress: 'دمشق',
      destinationAddress: 'حمص',
      departureTime: DateTime(2026, 7, 15, 8),
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
        child: MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: BlocProvider<BookingMeCubit>.value(
                  value: cubit,
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
    await tester.pump(const Duration(milliseconds: 600));
  }

  Finder chatIcon() => find.byIcon(Icons.chat_bubble_outline_rounded);

  group('متى تظهر الأيقونة', () {
    for (final status in const [
      'confirmed',
      'accepted',
      'ongoing',
      'completed',
      'finished',
    ]) {
      testWidgets('حجز «$status» — تظهر', (tester) async {
        await pump(tester, _booking(status: status));
        expect(chatIcon(), findsOneWidget);
      });
    }

    testWidgets('حالة بأحرف كبيرة تُقرأ كذلك', (tester) async {
      await pump(tester, _booking(status: 'CONFIRMED'));
      expect(chatIcon(), findsOneWidget);
    });
  });

  group('متى تختفي — لا محادثة بلا حجز قائم', () {
    for (final status in const [
      'pending',
      'cancelled',
      'canceled',
      'rejected',
    ]) {
      testWidgets('حجز «$status» — لا تظهر', (tester) async {
        await pump(tester, _booking(status: status));
        expect(chatIcon(), findsNothing);
      });
    }
  });

  group('الضغط', () {
    testWidgets('يفتح المحادثة مع سائق هذا الحجز بالذات', (tester) async {
      when(() => chatRepo.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async => right(77));

      await pump(tester, _booking());
      await tester.tap(chatIcon());
      await tester.pump();

      // userDriver = 3 — لا rideId ولا bookingId
      verify(() => chatRepo.startConversation(userId: 3)).called(1);
    });

    testWidgets('تبثّ الشاشةُ وجهةَ المحادثة باسم السائق', (tester) async {
      when(() => chatRepo.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async => right(77));

      final states = <BookingMeState>[];
      cubit.stream.listen(states.add);

      await pump(tester, _booking());
      await tester.tap(chatIcon());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final opened =
          states.whereType<BookingMeOpenConversation>().single;
      expect(opened.conversationId, 77);
      expect(opened.title, 'أحمد');
    });
  });
}
