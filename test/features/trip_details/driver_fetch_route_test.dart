import 'dart:io';

import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/trip_details/data/repo/trip_details_repo.dart';
import 'package:alatarekak/features/trip_details/presantaion/manger/cubit/tripdetails_cubit.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fixtures.dart';

class MockTripDetailsRepo extends Mock implements TripDetailsRepoIM {}

/// أي مسار تُجلب منه الرحلة.
///
/// `GET /rides/{id}` لا يرسل الحجوزات **عمداً**: لا يصحّ أن يطّلع أي
/// مستخدم على حجوزات رحلة ليست له. و`GET /rides/{id}/passangers` يرسلها
/// لسائقها.
///
/// وكانت شاشة التفاصيل تجلب الأول دائماً، فيفتح السائق رحلته من
/// «رحلاتي» فيجدها بلا حجوزات — وشاشة «حجوزات الرحلة» فارغة.
///
/// والقرار عند المستدعي لا بعد الجلب: أن الرحلة لي تعرفه الشاشة التي
/// فتحتها، ولا يمكن استنتاجه قبل أن يصل الرد.

const int _tripId = 5;

void main() {
  late MockTripDetailsRepo repo;
  late Directory tempDir;

  // الكيوبت يقرأ myid() ليحدّد وضع العرض — يحتاج صندوق الجلسة مفتوحاً
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('driver_fetch_route');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: 7,
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
    when(() => repo.featchTrip(any()))
        .thenAnswer((_) async => right(fakeTrip(id: _tripId)));
    when(() => repo.featchTripWithBookings(any()))
        .thenAnswer((_) async => right(fakeTrip(id: _tripId)));
  });

  TripDetailsCubit build() => TripDetailsCubit(tripDetailsRepoIM: repo);

  group('من «رحلاتي» — السائق', () {
    test('يُجلب مسار الحجوزات لا المسار العام', () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.fetchTrip(_tripId, asDriver: true);

      verify(() => repo.featchTripWithBookings(_tripId)).called(1);
      verifyNever(() => repo.featchTrip(any()));
    });
  });

  group('من البحث أو الحجوزات — راكب', () {
    test('يُجلب المسار العام لا مسار الحجوزات', () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.fetchTrip(_tripId);

      verify(() => repo.featchTrip(_tripId)).called(1);
      verifyNever(() => repo.featchTripWithBookings(any()));
    });

    test('الافتراضي هو المسار العام — لا يُطّلع على حجوزات غيرك سهواً',
        () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.fetchTrip(_tripId, asDriver: false);

      verifyNever(() => repo.featchTripWithBookings(any()));
    });
  });

  group('بقية السلوك لم يتغيّر', () {
    test('النجاح يُصدر الرحلة محمَّلة', () async {
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.fetchTrip(_tripId, asDriver: true);

      expect(cubit.state, isA<TripDetailsLoaded>());
      expect((cubit.state as TripDetailsLoaded).trip.id, _tripId);
    });

    test('فشل مسار السائق يُعرض معرَّباً', () async {
      when(() => repo.featchTripWithBookings(any())).thenAnswer(
          (_) async => left(const Filuar(message: 'Unauthenticated')));

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.fetchTrip(_tripId, asDriver: true);

      final state = cubit.state as TripDetailsError;
      expect(state.message, isNot(contains('Unauthenticated')));
    });

    test('الحجوزات تصل مع رحلة السائق', () async {
      when(() => repo.featchTripWithBookings(any())).thenAnswer(
        (_) async => right(TripModel.fromMap({
          'success': true,
          'data': {
            'id': _tripId,
            'driver_id': 7,
            'pickup_address': 'دمشق',
            'destination_address': 'حمص',
            'departure_time': '2030-01-01T09:00:00+03:00',
            'available_seats': 1,
            'price_per_seat': 5000,
            'status': 'active',
          },
          'bookings': {
            'total_bookings': 1,
            'list': [
              {
                'id': 101,
                'status': 'confirmed',
                'seats': 2,
                'communication_number': '+963911234567',
                'booked_at': '2026-08-18T08:30:00+00:00',
                'passenger': {'id': 15, 'name': 'أحمد خليل', 'avatar': null},
              },
            ],
          },
        })),
      );

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.fetchTrip(_tripId, asDriver: true);

      final trip = (cubit.state as TripDetailsLoaded).trip;
      expect(trip.booking, hasLength(1),
          reason: 'هذا ما كان يضيع: زرّ «عرض الحجوزات» يفتح شاشة فارغة');
      expect(trip.booking.first.userName, 'أحمد خليل');
    });
  });
}
