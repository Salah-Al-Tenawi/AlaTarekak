import 'dart:io';

import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/service/hive_services.dart';
import 'package:alatarekak/features/auth/data/model/user_model.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/data_source/booking_user_trip_remote_data.dart';
import 'package:alatarekak/features/trip_booking/data/data%20source/booking_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockApi extends Mock implements ApiConSumer {}

/// مسارا بلاغ الغياب — نصّاً ومُعرِّفاً.
///
/// **المعرّفان مختلفان وهنا مكمن الغلط**: بلاغ السائق يأخذ رقم **الحجز**
/// (`POST /api/bookings/{bookingId}/passenger-no-show`)، وبلاغ الراكب
/// يأخذ رقم **الرحلة** (`POST /api/rides/{rideId}/driver-no-show`) — لأن
/// للراكب حجزاً واحداً في الرحلة فتجده الخدمة بنفسها. وتبديلهما لا يُنتج
/// خطأ ترجمة ولا استثناءً، بل 422 على كائن آخر أو بلاغاً في غير موضعه.
///
/// وكلاهما **بلا جسم**: إرسال حقول لا ينتظرها الخادم يمرّ صامتاً اليوم
/// ويصير خطأ تحقّق يوم يُضيَّق الفحص.
void main() {
  late MockApi api;
  late Directory tempDir;

  setUpAll(() async {
    // mytoken() يقرأ صندوق الجلسة
    tempDir = await Directory.systemTemp.createTemp('no_show_endpoints');
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
    when(() => api.post(any(),
        data: any(named: 'data'),
        header: any(named: 'header'))).thenAnswer((_) async => {
          'status': 'success',
          'message': 'No-show report submitted. The passenger has 2 hours '
              'to dispute.',
        });
  });

  group('السائق يبلّغ عن راكبه', () {
    test('POST /bookings/{bookingId}/passenger-no-show — بالمعرّف الصحيح',
        () async {
      await BookingUserTripRemoteData(api: api).passengerNoShow(88);

      verify(() => api.post('${ApiEndPoint.bookings}/88/passenger-no-show',
          header: any(named: 'header'))).called(1);
    });

    test('لا يُرسل إلى مسار الرحلات بالخطأ', () async {
      await BookingUserTripRemoteData(api: api).passengerNoShow(88);

      verifyNever(() => api.post('${ApiEndPoint.rides}/88/passenger-no-show',
          header: any(named: 'header')));
      verifyNever(() => api.post('${ApiEndPoint.rides}/88/driver-no-show',
          header: any(named: 'header')));
    });

    test('بلا جسم — الخادم لا ينتظر حقولاً', () async {
      await BookingUserTripRemoteData(api: api).passengerNoShow(88);

      verifyNever(() => api.post(any(),
          data: any(named: 'data', that: isNotNull),
          header: any(named: 'header')));
    });
  });

  group('الراكب يبلّغ عن سائقه', () {
    test('POST /rides/{rideId}/driver-no-show — برقم الرحلة لا الحجز',
        () async {
      await BookingRemoteDataSource(api: api).driverNoShow(42);

      verify(() => api.post('${ApiEndPoint.rides}/42/driver-no-show',
          header: any(named: 'header'))).called(1);
    });

    test('لا يُرسل إلى مسار الحجوزات بالخطأ', () async {
      await BookingRemoteDataSource(api: api).driverNoShow(42);

      verifyNever(() => api.post('${ApiEndPoint.bookings}/42/driver-no-show',
          header: any(named: 'header')));
    });

    test('بلا جسم كذلك', () async {
      await BookingRemoteDataSource(api: api).driverNoShow(42);

      verifyNever(() => api.post(any(),
          data: any(named: 'data', that: isNotNull),
          header: any(named: 'header')));
    });
  });

  group('المسارات تحت /api', () {
    test('الجذر واحد للمسارين', () {
      expect(ApiEndPoint.bookings, contains('/api/bookings'));
      expect(ApiEndPoint.rides, contains('/api/rides'));
    });
  });
}
