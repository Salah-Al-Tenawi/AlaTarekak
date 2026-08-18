import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/route/route_name.dart';
import 'package:alatarekak/core/them/them_app.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/manger/cubit/booking_user_in_trip_cubit.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/view/booking_user_in_trip.dart';
import 'package:alatarekak/features/chat/domain/repo/chat_repo.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';

class MockRepo extends Mock implements BookingUsersInTripRepoImp {}

class MockChatRepo extends Mock implements ChatRepo {}

/// مراسلة الراكب من بطاقة حجزه.
///
/// سياسة التطبيق: لا محادثة بلا حجز — فالزرّ يظهر للحجز المؤكَّد وحده،
/// لا للطلب المعلَّق الذي لم يوافق عليه السائق بعد.
///
/// وحتى وقتٍ قريب كان معرّف الراكب يُقرأ صفراً: الرد يضعه تحت
/// `passenger` وكان القارئ يبحث عنه تحت `user`. فيُفتح الزرّ محادثةً مع
/// المستخدم رقم صفر.

const int _rideId = 42;
const int _passengerId = 15;

TripModel _trip({String firstStatus = 'confirmed'}) => TripModel.fromMap({
      'success': true,
      'data': {
        'id': _rideId,
        'driver_id': 7,
        'pickup_address': 'دمشق',
        'destination_address': 'حمص',
        'departure_time': '2030-01-01T09:00:00+03:00',
        'available_seats': 1,
        'price_per_seat': 5000,
        'status': 'active',
      },
      'bookings': {
        'total_bookings': 2,
        'list': [
          {
            'id': 101,
            'status': firstStatus,
            'seats': 2,
            'communication_number': '+963911234567',
            'booked_at': '2026-08-18T08:30:00+00:00',
            'passenger': {
              'id': _passengerId,
              'name': 'أحمد خليل',
              'avatar': null,
            },
          },
          {
            'id': 102,
            'status': 'pending',
            'seats': 1,
            'communication_number': '+963922345678',
            'booked_at': '2026-08-18T09:00:00+00:00',
            'passenger': {'id': 23, 'name': 'سارة منصور', 'avatar': null},
          },
        ],
      },
    });

void main() {
  late MockRepo repo;
  late MockChatRepo chatRepo;
  late BookingUserInTripCubit cubit;

  setUp(() {
    repo = MockRepo();
    chatRepo = MockChatRepo();
    Get.testMode = true;
    cubit = BookingUserInTripCubit(repo, chatRepo: chatRepo);
  });

  tearDown(() async {
    await cubit.close();
    Get.reset();
  });

  Future<void> pump(WidgetTester tester, {String firstStatus = 'confirmed'}) async {
    when(() => repo.tripPassengers(_rideId))
        .thenAnswer((_) async => right(_trip(firstStatus: firstStatus)));

    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => GetMaterialApp(
          theme: ThemApp.lightThem,
          initialRoute: '/bookings',
          getPages: [
            GetPage(
              name: '/bookings',
              page: () => BlocProvider<BookingUserInTripCubit>.value(
                value: cubit,
                child: const BookingUserINTrip(),
              ),
            ),
            // المحادثة مسار حقيقي في التطبيق — بدونه يرمي GetX عند التنقّل
            GetPage(
              name: RouteName.chatScreen,
              page: () => const Scaffold(body: Text('شاشة المحادثة')),
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
    Get.offAllNamed('/bookings', arguments: {'rideId': _rideId});
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
  }

  group('الحجز المؤكَّد', () {
    testWidgets('زرّ المراسلة ظاهر', (tester) async {
      await pump(tester);

      expect(find.text('أحمد خليل'), findsOneWidget);
      expect(find.text('مراسلة'), findsOneWidget);
    });

    testWidgets('الضغط يفتح محادثة مع الراكب نفسه لا مع صفر', (tester) async {
      when(() => chatRepo.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async => right(77));

      await pump(tester);
      await tester.tap(find.text('مراسلة'));
      await tester.pumpAndSettle();

      verify(() => chatRepo.startConversation(userId: _passengerId)).called(1);
      expect(find.text('شاشة المحادثة'), findsOneWidget,
          reason: 'الزرّ يفتح المحادثة فعلاً لا يكتفي بإنشائها');
    });

    testWidgets('تعذّر فتح المحادثة يُعرض معرَّباً', (tester) async {
      when(() => chatRepo.startConversation(userId: any(named: 'userId')))
          .thenAnswer((_) async => left(const Filuar(message: 'chat down')));

      await pump(tester);
      await tester.tap(find.text('مراسلة'));
      await tester.pumpAndSettle();

      expect(find.textContaining('chat down'), findsNothing);
    });
  });

  group('الطلب المعلَّق', () {
    testWidgets('قبول ورفض بلا مراسلة — لا محادثة بلا حجز', (tester) async {
      await pump(tester, firstStatus: 'pending');

      expect(find.text('قبول'), findsWidgets);
      expect(find.text('رفض'), findsWidgets);
      expect(find.text('مراسلة'), findsNothing);
    });
  });
}
