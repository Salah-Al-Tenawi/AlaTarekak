import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';
import 'package:alatarekak/features/booking_user_in_trip/presantion/manger/cubit/booking_user_in_trip_cubit.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockRepo extends Mock implements BookingUsersInTripRepoImp {}

/// شاشة «حجوزات الرحلة» تجلب بنفسها.
///
/// كانت تعرض ما مرّرته إليها شاشة التفاصيل وحده — وذلك يأتي من
/// `GET /rides/{id}` لا من `GET /rides/{id}/passengers`. فإن لم يُرسل
/// الأول الحجوزات ظهرت الشاشة فارغة مهما بلغ عددها، ولم تتحدّث بعد
/// قبول أو رفض.

const int _rideId = 42;

TripModel get _tripWithBookings => TripModel.fromMap({
      'success': true,
      'data': {
        'id': _rideId,
        'driver_id': 7,
        'pickup_address': 'دمشق',
        'destination_address': 'حمص',
        'departure_time': '2026-08-19T09:00:00+03:00',
        'available_seats': 1,
        'price_per_seat': 5000,
        'status': 'active',
      },
      'bookings': {
        'total_bookings': 2,
        'seat_summary': {'total_capacity': 4, 'available': 1, 'confirmed': 2},
        'list': [
          {
            'id': 101,
            'status': 'confirmed',
            'seats': 2,
            'communication_number': '+963911234567',
            'booked_at': '2026-08-18T08:30:00+00:00',
            'passenger': {'id': 15, 'name': 'أحمد خليل', 'avatar': null},
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
  late BookingUserInTripCubit cubit;

  setUp(() {
    repo = MockRepo();
    cubit = BookingUserInTripCubit(repo);
  });

  tearDown(() => cubit.close());

  group('الجلب', () {
    test('تحميل ثم قائمة الحجوزات وموعد الانطلاق', () async {
      when(() => repo.tripPassengers(_rideId))
          .thenAnswer((_) async => right(_tripWithBookings));

      final seen = <BookingUserInTripState>[];
      cubit.stream.listen(seen.add);
      await cubit.loadBookings(_rideId);
      await Future<void>.delayed(Duration.zero);

      expect(seen.first, isA<BookingUserInTripFetching>());

      final loaded = seen.last as BookingUserInTripListLoaded;
      expect(loaded.bookings, hasLength(2));
      expect(loaded.bookings.first.userName, 'أحمد خليل');
      expect(loaded.bookings.first.numberPhone, '+963911234567');
      expect(loaded.departure.toIso8601String(), startsWith('2026-08-19'));
    });

    test('الموعد يأتي مع القائمة لا من الشاشة السابقة', () async {
      when(() => repo.tripPassengers(_rideId))
          .thenAnswer((_) async => right(_tripWithBookings));

      await cubit.loadBookings(_rideId);

      // بلاغ «لم يحضر» مرهون بهذا الموعد
      expect((cubit.state as BookingUserInTripListLoaded).departure, isNotNull);
    });

    test('الفشل يعرض رسالة معرَّبة', () async {
      when(() => repo.tripPassengers(_rideId)).thenAnswer(
          (_) async => left(const Filuar(message: 'Unauthenticated')));

      await cubit.loadBookings(_rideId);

      final state = cubit.state as BookingUserInTripErorr;
      expect(state.message, isNot(contains('Unauthenticated')));
      expect(state.message, isNotEmpty);
    });
  });

  group('التحديث الصامت', () {
    test('لا يُصدر حالة تحميل فوق قائمة معروضة', () async {
      when(() => repo.tripPassengers(_rideId))
          .thenAnswer((_) async => right(_tripWithBookings));

      final seen = <BookingUserInTripState>[];
      cubit.stream.listen(seen.add);
      await cubit.loadBookings(_rideId, silent: true);
      await Future<void>.delayed(Duration.zero);

      expect(seen.whereType<BookingUserInTripFetching>(), isEmpty,
          reason: 'وميض مؤشّر تحميل بعد كل قبول يُقلق القائمة');
      expect(seen.last, isA<BookingUserInTripListLoaded>());
    });

    test('فشله لا يمحو القائمة برسالة خطأ', () async {
      when(() => repo.tripPassengers(_rideId))
          .thenAnswer((_) async => left(const Filuar(message: 'down')));

      final seen = <BookingUserInTripState>[];
      cubit.stream.listen(seen.add);
      await cubit.loadBookings(_rideId, silent: true);
      await Future<void>.delayed(Duration.zero);

      expect(seen, isEmpty,
          reason: 'التحديث في الخلفية يفشل صامتاً — المعروض ما زال صالحاً');
    });
  });
}
