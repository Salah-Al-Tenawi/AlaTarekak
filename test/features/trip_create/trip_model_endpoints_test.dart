import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// [TripModel] يُغذّى من **خمسة مسارات** بأشكال مختلفة:
///
///   POST /rides/create-with-route   → fromJson(...).first   إنشاء رحلة
///   GET  /rides                     → fromJson (قائمة)      رحلاتي
///   GET  /rides/{id}                → fromMap               التفاصيل/البحث
///   GET  /rides/{id}/passengers     → fromMap               رحلة واحدة
///   POST /search                    → fromJson (قائمة)      البحث
///
/// الملاحظة 18: الرحلة تصل بشكلين — «محوَّل» بكائن `driver` و`departure`
/// و`seats.available`، و«خام» بـ `driver_id` و`departure_time` و
/// `available_seats`. هذه الاختبارات تُثبّت أن الخمسة تُقرأ، فأي تغيير
/// في أحدها يسقط هنا لا على جهاز مستخدم.

/// الشكل الخام كما يصل من `GET /rides` — مرصود من الإنتاج 2026-08-18.
Map<String, dynamic> _rawRide({int id = 538}) => {
      'id': id,
      'driver_id': 1001,
      'pickup_address': 'سعسع, محافظة ريف دمشق, سوريا',
      'pickup_lat': null,
      'pickup_lng': null,
      'destination_address': 'الهامة, محافظة ريف دمشق',
      'destination_lat': null,
      'destination_lng': null,
      'pickup_location': {'lat': 33.307457, 'lng': 36.012828},
      'destination_location': {'lat': 33.561093, 'lng': 36.222656},
      'distance': 47214,
      'duration': 3140,
      'route_geometry': {'type': 'LineString', 'coordinates': []},
      'chosen_route_index': 0,
      'departure_time': '2026-08-20T16:00:00.000000Z',
      'available_seats': 1,
      'price_per_seat': '23000.00',
      'vehicle_type': 'crolla',
      'payment_method': 'cash',
      'booking_type': 'direct',
      'status': 'active',
      'notes': null,
      'communication_number': '+963988626577',
      'cash_creation_fee': '1150.00',
      'created_at': '2026-08-18T10:06:54.000000Z',
      'bookings_count': 0,
    };

/// الشكل المحوَّل — كائن driver متداخل وأسماء حقول أخرى.
Map<String, dynamic> _richRide({int id = 7}) => {
      'id': id,
      'driver': {'id': 1001, 'name': 'يزن صلاح', 'avatar': null},
      'pickup': {
        'address': 'دمشق',
        'coordinates': {'lat': 33.5, 'lng': 36.3}
      },
      'destination': {
        'address': 'حمص',
        'coordinates': {'lat': 34.7, 'lng': 36.7}
      },
      'departure': '2026-08-20T16:00:00.000000Z',
      'seats': {'available': 3, 'booked': 1, 'total': 4},
      'price_per_seat': '25000.00',
      'status': 'active',
      'distance': {'meters': 162117, 'kilometers': 162.1},
      'duration': {'seconds': 6144, 'minutes': 102},
      'vehicle_type': 'crolla',
      'payment_method': 'e-pay',
      'booking_type': 'direct',
      'route': {'index': 1},
      'communication_number': '+963988626577',
      'created_at': '2026-08-17T10:44:15.000000Z',
      'bookings_count': 1,
    };

void main() {
  group('GET /rides — رحلاتي (الشكل الخام، قائمة تحت data)', () {
    test('القائمة تُقرأ كاملة', () {
      final trips = TripModel.fromJson({
        'success': true,
        'data': [_rawRide(id: 538), _rawRide(id: 537)],
      });

      expect(trips, hasLength(2));
      expect(trips.map((t) => t.id), [538, 537]);
    });

    test('الحقول المسطّحة تُقرأ بأسمائها الخام', () {
      final t = TripModel.fromMap(_rawRide());

      expect(t.seatsAvailable, 1, reason: 'available_seats لا seats.available');
      expect(t.pricePerSeat, '23000.00');
      expect(t.chosenRouteIndex, 0, reason: 'chosen_route_index لا route.index');
      expect(t.communicationNumber, '+963988626577');
      expect(t.status, 'active');
    });

    test('الإحداثيات من pickup_location حين تصل المسطّحة null', () {
      final t = TripModel.fromMap(_rawRide());

      expect(t.pickup.coordinates.lat, closeTo(33.307457, 0.0001));
      expect(t.pickup.coordinates.lng, closeTo(36.012828, 0.0001));
      expect(t.destination.coordinates.lat, closeTo(33.561093, 0.0001));
    });

    test('driver_id وحده بلا كائن driver لا يُسقط التفكيك', () {
      expect(TripModel.fromMap(_rawRide()).driver.id, 1001);
    });

    test('distance و duration أرقام مفردة لا كائنات', () {
      final t = TripModel.fromMap(_rawRide());

      expect(t.distance.meters, 47214);
      expect(t.duration.seconds, 3140);
    });

    test('route_geometry فارغة لا تكسر شيئاً (الملاحظة 19)', () {
      expect(() => TripModel.fromMap(_rawRide()), returnsNormally);
    });
  });

  group('الشكل المحوَّل — driver متداخل وأسماء أخرى', () {
    test('كائن driver يُقرأ باسمه', () {
      final t = TripModel.fromMap(_richRide());

      expect(t.driver.id, 1001);
      expect(t.driver.name, 'يزن صلاح');
    });

    test('seats كائن و route.index و distance/duration كائنات', () {
      final t = TripModel.fromMap(_richRide());

      expect(t.seatsAvailable, 3);
      expect(t.seatsBooked, 1);
      expect(t.chosenRouteIndex, 1);
      expect(t.distance.meters, 162117);
      expect(t.duration.seconds, 6144);
    });
  });

  group('المغلَّفات — كل مسار يغلّف بطريقته', () {
    test('POST /rides/create-with-route: مفتاح ride', () {
      final trips = TripModel.fromJson({
        'status': 'success',
        'message': 'Ride created',
        'ride': _rawRide(id: 601),
      });

      expect(trips, hasLength(1));
      expect(trips.first.id, 601);
    });

    test('مفتاح data لرحلة مفردة', () {
      final trips =
          TripModel.fromJson({'success': true, 'data': _richRide(id: 9)});
      expect(trips.single.id, 9);
    });

    test('POST /search: قائمة تحت data', () {
      final trips = TripModel.fromJson({
        'success': true,
        'data': [_richRide(id: 11), _richRide(id: 12)],
      });
      expect(trips.map((t) => t.id), [11, 12]);
    });

    test('قائمة تحت rides', () {
      final trips = TripModel.fromJson({
        'rides': [_rawRide(id: 20)]
      });
      expect(trips.single.id, 20);
    });

    test('مُرقِّم Laravel: rides.data', () {
      final trips = TripModel.fromJson({
        'rides': {
          'current_page': 1,
          'data': [_rawRide(id: 30)],
          'last_page': 3,
        }
      });
      expect(trips.single.id, 30);
    });

    test('قائمة عارية بلا مغلَّف', () {
      expect(TripModel.fromJson([_rawRide(id: 40)]).single.id, 40);
    });

    test('رحلة مفردة عارية بلا مغلَّف', () {
      expect(TripModel.fromJson(_rawRide(id: 50)).single.id, 50);
    });
  });

  group('ما يجب أن يُشخَّص لا أن ينهار', () {
    test('غياب المعرّف يسمّي الحقل ويعدّد ما وصل', () {
      final bad = _rawRide()..remove('id');

      expect(
        () => TripModel.fromMap(bad),
        throwsA(predicate((e) =>
            e.toString().contains('id') &&
            e.toString().contains('TripModel'))),
      );
    });

    test('غياب موعد الانطلاق كذلك', () {
      final bad = _rawRide()..remove('departure_time');

      expect(
        () => TripModel.fromMap(bad),
        throwsA(predicate((e) => e.toString().contains('departure'))),
      );
    });

    test('صفّ مكسور بين صفوف سليمة لا يُسقط القائمة كلها', () {
      final trips = TripModel.fromJson({
        'data': [_rawRide(id: 1), 'ليس كائناً', _rawRide(id: 2)]
      });
      expect(trips.map((t) => t.id), [1, 2]);
    });
  });
}
