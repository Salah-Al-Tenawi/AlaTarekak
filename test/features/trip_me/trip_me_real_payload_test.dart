import 'dart:io';

import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:hive/hive.dart';
import 'package:alatarekak/features/trip_me/presantion/view/widget/trip_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// شاشة «رحلاتي» بحمولة `GET /api/rides` الحقيقية.
///
/// الرد بالشكل **الخام** (الملاحظة 18): بلا كائن `driver`، والإحداثيات
/// المسطّحة `null`، و`distance`/`duration` أرقام مفردة لا كائنات،
/// و`route_geometry.coordinates` فارغة أحياناً.

Map<String, dynamic> _ride({
  required int id,
  required String price,
  required int seats,
  List<dynamic> coordinates = const [
    [36.01, 33.30],
    [36.22, 33.56]
  ],
  String? notes,
  String? cashFee,
  String paymentMethod = 'cash',
  String bookingType = 'direct',
  String status = 'active',
  int distance = 47214,
  int duration = 3140,
}) =>
    {
      'id': id,
      'driver_id': 1001,
      'pickup_address': 'سعسع, ناحية سعسع, منطقة قطنا, محافظة ريف دمشق, سوريا',
      'pickup_lat': null,
      'pickup_lng': null,
      'destination_address': 'الهامة, ناحية مركز قدسيا, محافظة ريف دمشق',
      'destination_lat': null,
      'destination_lng': null,
      'pickup_location': {'lat': 33.307457, 'lng': 36.012828},
      'destination_location': {'lat': 33.561093, 'lng': 36.222656},
      'distance': distance,
      'duration': duration,
      'route_geometry': {'type': 'LineString', 'coordinates': coordinates},
      'chosen_route_index': 0,
      'departure_time': '2026-08-20T16:00:00.000000Z',
      'finished_at': null,
      'driver_confirmed_at': null,
      'passengers_confirmed': 0,
      'available_seats': seats,
      'price_per_seat': price,
      'vehicle_type': 'crolla',
      'payment_method': paymentMethod,
      'booking_type': bookingType,
      'status': status,
      'notes': notes,
      'communication_number': '+963988626577',
      'cash_creation_fee': cashFee,
      'cash_fee_deferred': false,
      'created_at': '2026-08-18T10:06:54.000000Z',
      'updated_at': '2026-08-18T10:06:54.000000Z',
      'bookings_count': 0,
    };

/// الثماني رحلات كما وصلت من الإنتاج في 2026-08-18.
final _realResponse = {
  'success': true,
  'data': [
    _ride(id: 538, price: '23000.00', seats: 1, cashFee: '1150.00'),
    _ride(id: 537, price: '2000.00', seats: 2, cashFee: '200.00', distance: 5508, duration: 492),
    // route_geometry فارغة — الملاحظة 19
    _ride(id: 535, price: '29000.00', seats: 1, coordinates: const [], paymentMethod: 'e-pay'),
    _ride(id: 530, price: '114000.00', seats: 4, notes: '....... العودة', paymentMethod: 'e-pay', bookingType: 'request'),
    _ride(id: 536, price: '6000.00', seats: 2, coordinates: const [], paymentMethod: 'e-pay'),
    _ride(id: 529, price: '114000.00', seats: 4, notes: '.......', cashFee: '22800.00'),
    _ride(id: 528, price: '45000.00', seats: 4, notes: 'يمنع أصطحاب الكلاب أو العجيان', paymentMethod: 'e-pay', bookingType: 'request'),
    _ride(id: 527, price: '45000.00', seats: 1, cashFee: '2250.00'),
  ],
};

void main() {
  late Directory tempDir;

  // البطاقة تقرأ معرّف المستخدم من صندوق الجلسة لتعرف أهي رحلته
  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('trip_me_test');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    final box = await Hive.openBox<UserModel>(HiveBoxes.authBoxName);
    await box.put(
      HiveKeys.user,
      const UserModel(
        id: 1001, // driver_id في الحمولة الحقيقية
        firstName: 'يزن',
        lastName: 'صلاح',
        email: 'me@example.com',
        accessToken: 'a',
        refreshToken: 'r',
      ),
    );
  });

  tearDown(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('التفكيك يقبل الشكل الخام بلا استثناء', () {
    final trips = TripModel.fromJson(_realResponse);

    expect(trips, hasLength(8));
    expect(trips.first.id, 538);
    expect(trips.map((t) => t.id).toList(),
        [538, 537, 535, 530, 536, 529, 528, 527]);
  });

  group('بطاقة الرحلة تُرسم لكل رحلة وصلت فعلاً', () {
    for (final raw in (_realResponse['data']! as List)) {
      final map = raw as Map<String, dynamic>;
      testWidgets('رحلة ${map['id']} تُرسم بلا انهيار', (tester) async {
        tester.view.physicalSize = const Size(400, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final trip = TripModel.fromMap(map);

        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: ItemTrip(
                      trip: trip,
                      onTap: () {},
                      onCancel: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 700));

        expect(tester.takeException(), isNull);
      });
    }
  });
}
