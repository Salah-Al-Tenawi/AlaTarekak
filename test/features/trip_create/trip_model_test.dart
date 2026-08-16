import 'package:alatarekak/core/utils/functions/json_parse.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// رد `POST /rides/create-with-route` كما رصدناه من الخادم فعلاً: صفّ قاعدة
/// بيانات مسطّح تحت مفتاح `ride`، بلا كائن سائق ولا موقع متداخل، والمسافة
/// والمدّة أرقام مفردة، والسعر نصّ.
Map<String, dynamic> _rawCreateResponse({
  Object? id = 1,
  Object? departure = '2026-08-16T03:00:00.000000Z',
}) =>
    {
      'status': 'success',
      'message': 'Ride created successfully',
      'ride': {
        'id': id,
        'driver_id': 2,
        'pickup_address': 'النابوع, الزبداني, محافظة ريف دمشق, سوريا',
        'pickup_lat': null,
        'pickup_lng': null,
        'destination_address': 'ساحة الامويين',
        'destination_lat': null,
        'destination_lng': null,
        'pickup_location': {'lat': 33.725983, 'lng': 36.101908},
        'destination_location': {'lat': 33.514136, 'lng': 36.276052},
        'distance': 47818,
        'duration': 2469,
        'chosen_route_index': 1,
        'departure_time': departure,
        'available_seats': 4,
        'price_per_seat': '26000.00',
        'vehicle_type': 'Toyota corolaa',
        'payment_method': 'cash',
        'booking_type': 'request',
        'status': 'active',
        'notes': 'قد اتأخر قليلا بسبب زحمة الطريق',
        'communication_number': '+963988626577',
        'cash_creation_fee': '5200.00',
      },
    };

/// الشكل المحوَّل الذي ترسله مسارات أخرى — كائنات متداخلة.
Map<String, dynamic> _transformed() => {
      'data': {
        'id': 12,
        'driver': {'id': 3, 'name': 'أحمد', 'avatar': null, 'rating': 4.5},
        'pickup': {
          'address': 'دمشق',
          'coordinates': {'lat': 33.51, 'lng': 36.29},
        },
        'destination': {
          'address': 'حمص',
          'coordinates': {'lat': 34.73, 'lng': 36.71},
        },
        'departure': '2026-07-15T08:00:00Z',
        'seats_available': 3,
        'seats_booked': 1,
        'price_per_seat': '25000',
        'status': 'active',
        'distance': {'meters': 160000, 'kilometers': 160.0},
        'duration': {'seconds': 7200, 'minutes': 120},
        'vehicle_type': 'sedan',
        'payment_method': 'wallet',
        'booking_type': 'instant',
        'notes': null,
        'created_at': '2026-07-01T10:00:00Z',
        'chosen_route_index': 0,
        'communication_number': '0999999999',
        'bookings': const [],
      }
    };

void main() {
  group('TripModel — الصفّ الخام (رد إنشاء الرحلة)', () {
    test('الرحلة تُقرأ من المغلَّف ride لا من جذر الرد', () {
      final trip = TripModel.fromJson(_rawCreateResponse()).first;
      expect(trip.id, 1);
      expect(trip.status, 'active');
    });

    test('driver_id المفرد يكفي لمعرفة صاحب الرحلة', () {
      final trip = TripModel.fromMap(_rawCreateResponse());
      expect(trip.driver.id, 2,
          reason: 'الشاشة تقارنه بالمستخدم الحالي لتختار واجهة السائق');
      expect(trip.driver.name, isEmpty);
    });

    test('العنوان والإحداثيات يُجمعان من الحقول المسطّحة', () {
      final trip = TripModel.fromMap(_rawCreateResponse());
      expect(trip.pickup.address, contains('الزبداني'));
      expect(trip.pickup.coordinates.lat, closeTo(33.725983, 1e-6));
      // pickup_lat فارغ لكن pickup_location يحمل القيمة
      expect(trip.destination.coordinates.lng, closeTo(36.276052, 1e-6));
    });

    test('departure_time يُقرأ حين يغيب departure', () {
      final trip = TripModel.fromMap(_rawCreateResponse());
      expect(trip.departure.toUtc(), DateTime.utc(2026, 8, 16, 3));
    });

    test('المسافة والمدّة رقمان مفردان يُشتقّ منهما الكيلومتر والدقيقة', () {
      final trip = TripModel.fromMap(_rawCreateResponse());
      expect(trip.distance.meters, 47818);
      expect(trip.distance.kilometers, closeTo(47.818, 1e-3));
      expect(trip.duration.seconds, 2469);
      expect(trip.duration.minutes, 41);
    });

    test('available_seats يُقرأ حين يغيب seats_available', () {
      final trip = TripModel.fromMap(_rawCreateResponse());
      expect(trip.seatsAvailable, 4);
      expect(trip.seatsBooked, 0, reason: 'لا حجوزات على رحلة أُنشئت للتوّ');
    });

    test('غياب created_at لا يُسقط التفكيك', () {
      expect(TripModel.fromMap(_rawCreateResponse()).createdAt, isNull);
    });
  });

  group('TripModel — الشكل المحوَّل ما زال يعمل', () {
    test('الكائنات المتداخلة تُقرأ كما هي', () {
      final trip = TripModel.fromMap(_transformed());
      expect(trip.id, 12);
      expect(trip.driver.name, 'أحمد');
      expect(trip.driver.rating, 4.5, reason: 'التقييم عشري لا يُقرَّب');
      expect(trip.pickup.address, 'دمشق');
      expect(trip.distance.kilometers, 160.0);
      expect(trip.duration.minutes, 120);
      expect(trip.seatsBooked, 1);
      expect(trip.createdAt, isNotNull);
    });
  });

  group('TripModel.fromJson — أشكال التغليف', () {
    test('قائمة مباشرة', () {
      final list = TripModel.fromJson([_transformed()['data']]);
      expect(list, hasLength(1));
    });

    test('قائمة تحت المفتاح rides', () {
      final list = TripModel.fromJson({
        'status': 'success',
        'rides': [_transformed()['data'], _rawCreateResponse()['ride']],
      });
      expect(list, hasLength(2));
      expect(list.last.id, 1);
    });

    test('مُرقِّم Laravel تحت rides لا يُقرأ كرحلة واحدة', () {
      final list = TripModel.fromJson({
        'rides': {
          'current_page': 1,
          'last_page': 3,
          'data': [_transformed()['data']],
        }
      });
      expect(list, hasLength(1));
      expect(list.single.id, 12);
    });

    test('رحلة مفردة بلا تغليف', () {
      expect(TripModel.fromJson(_transformed()['data']!).single.id, 12);
    });
  });

  group('TripModel — الحقول التي لا تقوم الرحلة بدونها', () {
    test('غياب المعرّف يرفع خطأً يسمّي الحقل ويعدّد ما وصل', () {
      expect(
        () => TripModel.fromMap(_rawCreateResponse(id: null)),
        throwsA(isA<JsonFieldMissing>()
            .having((e) => e.field, 'field', 'id')
            .having((e) => e.toString(), 'message', contains('driver_id'))),
      );
    });

    test('غياب موعد الانطلاق يرفع خطأً مسمّى لا انهياراً نوعياً', () {
      expect(
        () => TripModel.fromMap(_rawCreateResponse(departure: null)),
        throwsA(isA<JsonFieldMissing>()
            .having((e) => e.field, 'field', 'departure')),
      );
    });

    test('المعرّف النصّي يُقبل — بعض المسارات ترسله نصاً', () {
      expect(TripModel.fromMap(_rawCreateResponse(id: '77')).id, 77);
    });
  });

  group('TripModel — أسماء حقل المقاعد المختلفة بين المسارات', () {
    /// ظهرت رحلة فيها ثلاثة مقاعد فارغة بعدّاد صفر في شاشة التفاصيل،
    /// فمُنع الراكب من الحجز: المسار سمّى الحقل باسم لا يقرؤه التطبيق.
    TripModel withSeatKey(String key, int value) {
      final r = _rawCreateResponse();
      final ride = r['ride'] as Map<String, dynamic>;
      ride.remove('available_seats');
      ride[key] = value;
      return TripModel.fromMap(r);
    }

    for (final key in const [
      'seats_available',
      'available_seats',
      'remaining_seats',
      'seats_left',
    ]) {
      test('«$key» يُقرأ كعدد مقاعد متاحة', () {
        expect(withSeatKey(key, 3).seatsAvailable, 3);
      });
    }

    test('غياب كل الأسماء يعطي صفراً بلا انهيار', () {
      final r = _rawCreateResponse();
      (r['ride'] as Map<String, dynamic>).remove('available_seats');
      expect(TripModel.fromMap(r).seatsAvailable, 0);
    });
  });

  group('TripModel — رد البحث الفعلي (مغلَّف success + data)', () {
    /// الرد كما رصدناه من الخادم: قائمة تحت `data`، وصفّ مسطّح لكلّ رحلة،
    /// وكائن سائق كامل لكن باسم مفصول إلى `first_name` و`last_name`.
    Map<String, dynamic> searchResponse() => {
          'success': true,
          'data': [
            {
              'id': 2,
              'driver_id': 2,
              'pickup_address': 'السفارة الأرجنتينية',
              'pickup_lat': null,
              'pickup_lng': null,
              'destination_address': 'حي الفالوجة, اليرموك, دمشق',
              'pickup_location': {'lat': 33.520877, 'lng': 36.283538},
              'destination_location': {'lat': 33.476405, 'lng': 36.305053},
              'distance': 7132,
              'duration': 551,
              'route_geometry': {'type': 'LineString', 'coordinates': []},
              'chosen_route_index': 0,
              'departure_time': '2026-08-16T10:55:00.000000Z',
              'passengers_confirmed': 0,
              'available_seats': 3,
              'price_per_seat': '7000.00',
              'vehicle_type': 'Toyota corolaa',
              'payment_method': 'e-pay',
              'booking_type': 'direct',
              'status': 'active',
              'notes': null,
              'communication_number': '+963988626577',
              'cash_creation_fee': null,
              'cash_fee_deferred': false,
              'created_at': '2026-08-15T22:44:11.000000Z',
              'driver': {
                'id': 2,
                'first_name': 'أحمد',
                'last_name': 'العظمة',
                'email': 'azy3449@gmail.com',
                'avatar': null,
                'is_verified_driver': 1,
                'verification_status': 'approved',
              },
            }
          ]
        };

    test('القائمة تُقرأ من data داخل مغلَّف success', () {
      final trips = TripModel.fromJson(searchResponse());
      expect(trips, hasLength(1));
      expect(trips.single.id, 2);
    });

    test('اسم السائق يُركَّب من first_name و last_name', () {
      final trip = TripModel.fromJson(searchResponse()).single;
      expect(trip.driver.name, 'أحمد العظمة',
          reason: 'قراءة name وحده كانت تُظهر بطاقة سائق بلا اسم');
      expect(trip.driver.id, 2);
    });

    test('غياب rating لا يُسقط التفكيك', () {
      expect(TripModel.fromJson(searchResponse()).single.driver.rating, 0);
    });

    test('المقاعد والسعر والدفع تُقرأ من الصفّ المسطّح', () {
      final trip = TripModel.fromJson(searchResponse()).single;
      expect(trip.seatsAvailable, 3);
      expect(trip.pricePerSeat, '7000.00');
      expect(trip.paymentMethod, 'e-pay');
      expect(trip.bookingType, 'direct');
    });

    test('الإحداثيات من *_location رغم أن *_lat فارغة', () {
      final trip = TripModel.fromJson(searchResponse()).single;
      expect(trip.pickup.coordinates.lat, closeTo(33.520877, 1e-6));
      expect(trip.destination.coordinates.lng, closeTo(36.305053, 1e-6));
    });
  });

  group('DriverModel — صور الاسم المختلفة', () {
    TripModel withDriver(Map<String, dynamic> driver) {
      final r = _rawCreateResponse();
      (r['ride'] as Map<String, dynamic>)['driver'] = driver;
      return TripModel.fromMap(r);
    }

    test('حقل name المفرد يُفضَّل حين يصل', () {
      expect(withDriver({'id': 9, 'name': 'سامر'}).driver.name, 'سامر');
    });

    test('اسم أول بلا اسم أخير لا يترك فراغاً زائداً', () {
      expect(withDriver({'id': 9, 'first_name': 'سامر'}).driver.name, 'سامر');
    });

    test('غياب الاسم كلياً يعطي نصاً فارغاً لا انهياراً', () {
      expect(withDriver({'id': 9}).driver.name, isEmpty);
    });
  });

  group('TripModel — المقاعد المحجوزة تُشتقّ من الحجوزات', () {
    TripModel withBookings(List<Map<String, dynamic>> bookings) {
      final r = _rawCreateResponse();
      final ride = r['ride'] as Map<String, dynamic>;
      ride['bookings'] = bookings;
      return TripModel.fromMap(r);
    }

    test('تُجمع مقاعد الحجوزات حين يغيب العدّاد', () {
      final trip = withBookings([
        {'id': 1, 'seats': 2, 'status': 'confirmed', 'user': {'id': 5}},
        {'id': 2, 'seats': 1, 'status': 'pending', 'user': {'id': 6}},
      ]);
      expect(trip.seatsBooked, 3);
    });

    test('الحجوزات الملغاة والمرفوضة لا تُحتسب', () {
      final trip = withBookings([
        {'id': 1, 'seats': 2, 'status': 'confirmed', 'user': {'id': 5}},
        {'id': 2, 'seats': 4, 'status': 'cancelled', 'user': {'id': 6}},
        {'id': 3, 'seats': 3, 'status': 'rejected', 'user': {'id': 7}},
      ]);
      expect(trip.seatsBooked, 2);
    });

    test('العدّاد الصريح يُقدَّم على الاشتقاق', () {
      final r = _rawCreateResponse();
      final ride = r['ride'] as Map<String, dynamic>;
      ride['seats_booked'] = 7;
      ride['bookings'] = [
        {'id': 1, 'seats': 2, 'status': 'confirmed', 'user': {'id': 5}}
      ];
      expect(TripModel.fromMap(r).seatsBooked, 7);
    });

    test('بلا حجوزات ولا عدّاد يبقى صفراً', () {
      expect(withBookings(const []).seatsBooked, 0);
    });
  });

  group('TripModel — رد تفاصيل الرحلة الفعلي (الشكل الغنيّ)', () {
    /// `GET /rides/{id}` كما رصدناه: كائنات متداخلة، والمقاعد مجموعة في
    /// كائن `seats` والمسار في `route` — لا حقولاً مفردة كما في البحث.
    Map<String, dynamic> showResponse() => {
          'success': true,
          'data': {
            'id': 2,
            'driver': {
              'id': 2,
              'name': 'أحمد العظمة',
              'avatar': 'http://192.168.0.104:8000/storage/profiles/2.jpg',
              'rating': 0,
            },
            'pickup': {
              'address': 'السفارة الأرجنتينية',
              'coordinates': {'lat': 33.520877, 'lng': 36.283538},
            },
            'destination': {
              'address': 'حي الفالوجة, اليرموك, دمشق',
              'coordinates': {'lat': 33.476405, 'lng': 36.305053},
            },
            'departure_time': '2026-08-16T13:55:00+03:00',
            'departure_time_human': 'Aug 16, 2026 at 1:55 PM',
            'seats': {'available': 3, 'booked': 0, 'total': 3},
            'price_per_seat': '7000.00',
            'status': 'active',
            'distance': {'meters': 7132, 'kilometers': 7.1},
            'duration': {'seconds': 551, 'minutes': 9, 'human': '9m'},
            'vehicle_type': 'Toyota corolaa',
            'payment_method': 'e-pay',
            'booking_type': 'direct',
            'communication_number': '+963988626577',
            'notes': null,
            'route': {
              'index': 2,
              'geometry': {'type': 'LineString', 'coordinates': []},
            },
            'created_at': '2026-08-16T01:44:11+03:00',
          }
        };

    test('المقاعد تُقرأ من كائن seats المتداخل لا من حقل مفرد', () {
      final trip = TripModel.fromMap(showResponse());
      expect(trip.seatsAvailable, 3,
          reason: 'قراءة seats كرقم كانت تعطي صفراً فتمنع الحجز');
      expect(trip.seatsBooked, 0);
    });

    test('فهرس المسار يُقرأ من route.index', () {
      expect(TripModel.fromMap(showResponse()).chosenRouteIndex, 2,
          reason: 'خريطة المسار كانت تُفتح دائماً على المسار صفر');
    });

    test('السائق واسمه وصورته تصل من الكائن المتداخل', () {
      final driver = TripModel.fromMap(showResponse()).driver;
      expect(driver.name, 'أحمد العظمة');
      expect(driver.avatar, startsWith('http'));
    });

    test('بقية الحقول المتداخلة تُقرأ كما هي', () {
      final trip = TripModel.fromMap(showResponse());
      expect(trip.pickup.address, 'السفارة الأرجنتينية');
      expect(trip.distance.kilometers, 7.1);
      expect(trip.duration.minutes, 9);
      expect(trip.departure.toUtc(), DateTime.utc(2026, 8, 16, 10, 55));
      expect(trip.notes, isNull);
    });
  });
}
