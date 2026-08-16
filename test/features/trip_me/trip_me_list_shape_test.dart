import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// رد `GET /api/rides` (قائمة «رحلاتي») كما رصدناه من الخادم فعلاً:
/// صفوف قاعدة بيانات مسطّحة، السائق معرّفاً مفرداً، المسافة والمدّة أرقاماً،
/// والإحداثيات في `*_location` بينما `*_lat`/`*_lng` فارغة — ومعها عدّاد
/// `bookings_count` بلا قائمة حجوزات.
Map<String, dynamic> _listResponse() => {
      'success': true,
      'data': [
        {
          'id': 3,
          'driver_id': 2,
          'pickup_address': 'حي الفالوجة, اليرموك, محافظة دمشق, سوريا',
          'pickup_lat': null,
          'pickup_lng': null,
          'destination_address': 'السفارة الأرجنتينية',
          'destination_lat': null,
          'destination_lng': null,
          'pickup_location': {'lat': 33.476405, 'lng': 36.305053},
          'destination_location': {'lat': 33.520877, 'lng': 36.283538},
          'distance': 7823,
          'duration': 582,
          'route_geometry': {'type': 'LineString', 'coordinates': []},
          'chosen_route_index': 0,
          'departure_time': '2026-08-16T11:00:00.000000Z',
          'finished_at': '2026-08-16T12:51:43.000000Z',
          'driver_confirmed_at': null,
          'passengers_confirmed': 0,
          'available_seats': 2,
          'price_per_seat': '7000.00',
          'vehicle_type': 'Toyota corolaa',
          'payment_method': 'e-pay',
          'booking_type': 'direct',
          'status': 'finished',
          'notes': null,
          'communication_number': '+963988626577',
          'cash_creation_fee': null,
          'cash_fee_deferred': false,
          'created_at': '2026-08-15T22:44:40.000000Z',
          'updated_at': '2026-08-16T12:51:43.000000Z',
          'bookings_count': 0,
        },
        {
          'id': 2,
          'driver_id': 2,
          'pickup_address': 'السفارة الأرجنتينية',
          'pickup_lat': null,
          'pickup_lng': null,
          'destination_address': 'حي الفالوجة, اليرموك, محافظة دمشق, سوريا',
          'destination_lat': null,
          'destination_lng': null,
          'pickup_location': {'lat': 33.520877, 'lng': 36.283538},
          'destination_location': {'lat': 33.476405, 'lng': 36.305053},
          'distance': 7132,
          'duration': 551,
          'chosen_route_index': 0,
          'departure_time': '2026-08-16T10:55:00.000000Z',
          'available_seats': 2,
          'price_per_seat': '7000.00',
          'vehicle_type': 'Toyota corolaa',
          'payment_method': 'e-pay',
          'booking_type': 'direct',
          'status': 'active',
          'notes': null,
          'communication_number': '+963988626577',
          'created_at': '2026-08-15T22:44:11.000000Z',
          'bookings_count': 2,
        },
        {
          'id': 4,
          'driver_id': 2,
          'pickup_address': '110, براق, محافظة ريف دمشق, سوريا',
          'destination_address': 'التل, محافظة ريف دمشق, سوريا',
          'pickup_location': {'lat': 33.404104, 'lng': 36.372839},
          'destination_location': {'lat': 33.616255, 'lng': 36.306813},
          'distance': 31950,
          'duration': 1970,
          'chosen_route_index': 0,
          'departure_time': '2026-08-15T23:00:00.000000Z',
          'available_seats': 0,
          'price_per_seat': '15000.00',
          'vehicle_type': 'Toyota corolaa',
          'payment_method': 'cash',
          'booking_type': 'direct',
          'status': 'full',
          'notes': null,
          'communication_number': '+963988626577',
          'cash_creation_fee': '1500.00',
          'cash_fee_deferred': false,
          'created_at': '2026-08-15T22:49:10.000000Z',
          'bookings_count': 1,
        },
      ],
    };

List<TripModel> _parse() => TripModel.fromJson(_listResponse());

void main() {
  group('GET /rides — القائمة تُفكَّك كاملة', () {
    test('الرحلات الثلاث تصل بمعرّفاتها', () {
      expect(_parse().map((t) => t.id).toList(), [3, 2, 4]);
    });

    test('العناوين تُقرأ من الحقول المسطّحة', () {
      final trip = _parse().first;
      expect(trip.pickup.address, contains('الفالوجة'));
      expect(trip.destination.address, 'السفارة الأرجنتينية');
    });

    test('الإحداثيات تُقرأ من *_location رغم أن *_lat فارغة', () {
      final trip = _parse().first;
      expect(trip.pickup.coordinates.lat, closeTo(33.476405, 0.000001));
      expect(trip.destination.coordinates.lng, closeTo(36.283538, 0.000001));
    });

    test('المسافة والمدّة تُقرآن من الأرقام المفردة', () {
      final trip = _parse().first;
      expect(trip.distance.meters, 7823);
      expect(trip.distance.kilometers, closeTo(7.823, 0.001));
      expect(trip.duration.minutes, 10);
    });

    test('الحالات تصل كما هي — وكلها معروفة للشارة', () {
      expect(_parse().map((t) => t.status).toList(),
          ['finished', 'active', 'full']);
    });
  });

  group('عدد الحجوزات — الحقل الذي لم يكن يُقرأ', () {
    test('bookings_count يُقرأ لكل رحلة', () {
      expect(_parse().map((t) => t.bookingsCount).toList(), [0, 2, 1]);
    });

    test('عدد الحجوزات مستقل عن المقاعد المتاحة', () {
      // الرحلة 4: حجز واحد استهلك كل المقاعد
      final full = _parse().firstWhere((t) => t.id == 4);
      expect(full.bookingsCount, 1);
      expect(full.seatsAvailable, 0);
    });

    test('غياب العدّاد لا يرمي — يسقط إلى طول قائمة الحجوزات', () {
      final trip = TripModel.fromMap(const {
        'id': 9,
        'departure_time': '2026-08-16T11:00:00.000000Z',
        'bookings': [
          {'id': 1, 'seats': 2, 'status': 'accepted'},
          {'id': 2, 'seats': 1, 'status': 'accepted'},
        ],
      });
      expect(trip.bookingsCount, 2);
    });

    test('لا عدّاد ولا قائمة → صفر لا استثناء', () {
      final trip = TripModel.fromMap(const {
        'id': 9,
        'departure_time': '2026-08-16T11:00:00.000000Z',
      });
      expect(trip.bookingsCount, 0);
    });

    test('العدّاد ينجو من رحلة الكاش المحلي', () {
      final original = _parse()[1];
      final restored = TripModel.fromMap(original.toJson());
      expect(restored.bookingsCount, 2);
    });
  });

  group('الموعد يُحوَّل إلى التوقيت المحلي', () {
    test('departure_time بصيغة UTC يصير وقتاً محلياً', () {
      final trip = _parse().first;
      expect(trip.departure.isUtc, isFalse,
          reason: 'العرض بالتوقيت المحلي لا بـ UTC');
      expect(trip.departure.toUtc(),
          DateTime.parse('2026-08-16T11:00:00.000000Z'));
    });
  });

  group('السائق يصل معرّفاً مفرداً', () {
    test('driver_id يملأ المعرّف ويترك الاسم فارغاً', () {
      final trip = _parse().first;
      expect(trip.driver.id, 2);
      expect(trip.driver.name, isEmpty,
          reason: 'القائمة لا ترسل اسم السائق — البطاقة تعرض «رحلتي»');
    });
  });
}
