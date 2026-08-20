import 'dart:io';

import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/data_source/booking_user_trip_remote_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements ApiConSumer {}

/// مسار «الرحلة وحجوزاتها» — نصّاً لا معنىً.
///
/// المسار عند الخادم `passengers`، وكان مكتوباً هنا `passangers` بخطأ
/// إملائي بقي بعد تصحيحه في شاشة التفاصيل. فصار السائق يفتح «عرض
/// الحجوزات» من رحلته فيرى القائمة — لأن شاشة التفاصيل مرّرتها إليه —
/// ومعها «حدث خطأ غير متوقع» من طلب الشاشة الخاصّ الذي يعود 404.
///
/// لم يكن أي اختبار يفحص المسار المكتوب، فمرّ الخطأ صامتاً. هذا يثبّته
/// حرفاً بحرف — والمقارنة بالنصّ الكامل مقصودة: `contains('passengers')`
/// يمرّ على `passangers` أيضاً في بعض الصياغات.
void main() {
  late MockApi api;
  late Directory tempDir;

  setUpAll(() async {
    // mytoken() يقرأ صندوق الجلسة
    tempDir = await Directory.systemTemp.createTemp('passengers_endpoint');
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
        accessToken: 'token',
        refreshToken: 'refresh',
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
    api = MockApi();
    when(() => api.get(any(), header: any(named: 'header'))).thenAnswer(
      (_) async => {
        'success': true,
        'data': {
          'id': 5,
          'driver_id': 7,
          'pickup_address': 'دمشق',
          'destination_address': 'حمص',
          'pickup_location': {'lat': 33.5, 'lng': 36.3},
          'destination_location': {'lat': 34.7, 'lng': 36.7},
          'distance': 160000,
          'duration': 7200,
          'departure_time': '2026-09-01T08:00:00.000000Z',
          'available_seats': 2,
          'price_per_seat': '25000.00',
          'vehicle_type': 'sedan',
          'payment_method': 'cash',
          'booking_type': 'direct',
          'status': 'active',
          'communication_number': '+963988626577',
          'bookings_count': 0,
        },
      },
    );
  });

  test('tripPassengers يطلب /rides/{id}/passengers بالضبط', () async {
    final source = BookingUserTripRemoteData(api: api);

    await source.tripPassengers(5);

    verify(() => api.get('${ApiEndPoint.rides}/5/passengers',
        header: any(named: 'header'))).called(1);
  });

  test('لا يطلب الإملاء الخاطئ passangers', () async {
    final source = BookingUserTripRemoteData(api: api);

    await source.tripPassengers(5);

    verifyNever(() => api.get('${ApiEndPoint.rides}/5/passangers',
        header: any(named: 'header')));
  });

  test('المعرّف يدخل في المسار لا كوسيط استعلام', () async {
    final source = BookingUserTripRemoteData(api: api);

    await source.tripPassengers(41);

    final path = verify(() => api.get(captureAny(), header: any(named: 'header')))
        .captured
        .single as String;

    expect(path, endsWith('/41/passengers'));
    expect(path, isNot(contains('?')));
  });
}
