import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// `GET /rides/{id}/passangers` — الرد الحقيقي كما أرسله الباك إند.
///
/// كانت شاشة «حجوزات الرحلة» تظهر فارغة مهما بلغ عدد الحجوزات، لثلاثة
/// اختلافات في هذا الرد وحده:
///
///   1. `bookings` **شقيقة** لـ`data` لا داخلها، وكان القارئ ينزل إلى
///      `data` فتبقى خارج مداه.
///   2. `bookings` كائن `{total_bookings, seat_summary, list}` لا قائمة.
///   3. الراكب تحت `passenger` لا `user`، ورقم التواصل حقل في الحجز
///      نفسه لا في الراكب.

Map<String, dynamic> get _response => {
      'success': true,
      'data': {
        'id': 42,
        'driver_id': 7,
        'pickup_address': 'Damascus, Al-Midan',
        'destination_address': 'Homs, Al-Hamidiyeh',
        'departure_time': '2026-08-19T09:00:00+03:00',
        'available_seats': 1,
        'price_per_seat': 5000,
        'vehicle_type': 'sedan',
        'status': 'active',
        'payment_method': 'cash',
        'booking_type': 'direct',
        'notes': null,
      },
      'bookings': {
        'total_bookings': 2,
        'seat_summary': {
          'total_capacity': 4,
          'available': 1,
          'confirmed': 2,
          'pending': 1,
          'cancelled': 0,
          'completed': 0,
        },
        'list': [
          {
            'id': 101,
            'status': 'confirmed',
            'seats': 2,
            'communication_number': '+963911234567',
            'booked_at': '2026-08-18T08:30:00+00:00',
            'passenger': {
              'id': 15,
              'name': 'Ahmad Khalil',
              'avatar': 'http://localhost/storage/profiles/15_avatar.jpg',
            },
          },
          {
            'id': 102,
            'status': 'pending',
            'seats': 1,
            'communication_number': '+963922345678',
            'booked_at': '2026-08-18T09:00:00+00:00',
            'passenger': {'id': 23, 'name': 'Sara Mansour', 'avatar': null},
          },
        ],
      },
    };

void main() {
  group('الحجوزات تصل — وهو الخطأ المُصلَح', () {
    test('القائمة تُقرأ رغم أنها خارج data', () {
      final trip = TripModel.fromMap(_response);

      expect(trip.booking, hasLength(2),
          reason: 'كانت الشاشة تظهر فارغة لأن bookings شقيقة لـdata');
    });

    test('عدّاد الحجوزات من total_bookings', () {
      expect(TripModel.fromMap(_response).bookingsCount, 2);
    });
  });

  group('بيانات كل حجز', () {
    test('الراكب يُقرأ من passenger لا user', () {
      final first = TripModel.fromMap(_response).booking.first;

      expect(first.userName, 'Ahmad Khalil');
      expect(first.userId, 15);
      expect(first.avatar, contains('15_avatar.jpg'));
    });

    test('رقم التواصل من الحجز نفسه', () {
      final first = TripModel.fromMap(_response).booking.first;

      expect(first.numberPhone, '+963911234567',
          reason: 'الرقم حقل في الحجز لا في الراكب في هذا المسار');
    });

    test('المقاعد والحالة وتاريخ الحجز', () {
      final bookings = TripModel.fromMap(_response).booking;

      expect(bookings[0].seats, 2);
      expect(bookings[0].status, 'confirmed');
      expect(bookings[0].bookingat, startsWith('2026-08-18'));
      expect(bookings[1].status, 'pending');
      expect(bookings[1].userName, 'Sara Mansour');
      expect(bookings[1].avatar, isNull);
    });
  });

  group('المقاعد من seat_summary', () {
    test('المتاح من الحقل المسطّح', () {
      expect(TripModel.fromMap(_response).seatsAvailable, 1);
    });

    test('المحجوز = المؤكَّد + المعلَّق', () {
      expect(TripModel.fromMap(_response).seatsBooked, 3,
          reason: 'كلاهما يشغل مقعداً — و4 سعة ناقص 1 متاح = 3');
    });
  });

  group('بقية حقول الرحلة', () {
    test('تُقرأ من data كالمعتاد', () {
      final trip = TripModel.fromMap(_response);

      expect(trip.id, 42);
      expect(trip.driver.id, 7);
      expect(trip.pickup.address, 'Damascus, Al-Midan');
      expect(trip.destination.address, 'Homs, Al-Hamidiyeh');
      expect(trip.status, 'active');
      expect(trip.paymentMethod, 'cash');
      expect(trip.bookingType, 'direct');
    });
  });

  group('الأشكال الأخرى ما زالت تعمل', () {
    test('قائمة حجوزات داخل الرحلة مباشرةً', () {
      final trip = TripModel.fromMap({
        'id': 5,
        'driver_id': 2,
        'pickup_address': 'دمشق',
        'destination_address': 'حمص',
        'departure_time': '2026-08-19T09:00:00+03:00',
        'available_seats': 2,
        'price_per_seat': '1000',
        'status': 'active',
        'bookings': [
          {
            'id': 3,
            'user': {'id': 4, 'name': 'صلاح', 'avatar': null, 'rating': 0},
            'seats': 1,
            'status': 'pending',
            'booked_at': '2025-08-13T21:52:11+00:00',
            'total_price': 1000,
          },
        ],
      });

      expect(trip.booking, hasLength(1));
      expect(trip.booking.first.userName, 'صلاح');
      expect(trip.booking.first.totaPrice, 1000);
      expect(trip.seatsBooked, 1);
    });

    test('رحلة بلا حجوزات إطلاقاً', () {
      final trip = TripModel.fromMap({
        'id': 6,
        'driver_id': 2,
        'pickup_address': 'دمشق',
        'destination_address': 'حمص',
        'departure_time': '2026-08-19T09:00:00+03:00',
        'available_seats': 4,
        'price_per_seat': '1000',
        'status': 'active',
      });

      expect(trip.booking, isEmpty);
      expect(trip.bookingsCount, 0);
    });
  });
}
