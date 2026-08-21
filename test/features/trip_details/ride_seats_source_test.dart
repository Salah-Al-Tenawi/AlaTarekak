import 'package:alatarekak/core/utils/class/ride_booking_rules.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// من أين تُقرأ المقاعد — ومن يفتح زرّ الحجز.
///
/// بشهادة الباك إند: **`available` هو الحقل الموثوق وحده**. أما `booked`
/// و`total` فمكسوران — `GET /rides/{id}` لا يستدعي `loadCount` فيصل
/// `booked: 0` و`total: available`، وبقيّة المسارات تستدعيه بلا ترشيح
/// على الحالة فتُضخّمهما الحجوزات الملغاة.
///
/// وبشهادته أيضاً: `canBeBooked()` يقرأ الحالة وحدها ولا يعرف شيئاً عن
/// المقاعد. فـ`full` تعني «ليست منتهية ولا ملغاة» لا «ممتلئة فعلاً»،
/// والمقاعد تُفحص فحصاً منفصلاً.
Map<String, dynamic> _rideResponse({
  int capacity = 4,
  int available = 1,
  String status = 'active',
}) =>
    {
      'success': true,
      'data': {
        'id': 42,
        'driver_id': 5,
        'pickup_address': 'المزة، دمشق',
        'destination_address': 'درعا البلد',
        'departure_time': '2026-09-01T07:30:00+00:00',
        'price_per_seat': 25000,
        'status': status,
        // مكسورة: booked صفر دائماً، وtotal = available
        'seats': {'available': available, 'booked': 0, 'total': available},
      },
      'bookings': {
        'total_bookings': 3,
        'seat_summary': {
          'total_capacity': capacity,
          'available': available,
          'confirmed': capacity - available,
          'pending': 0,
        },
        'list': const [],
      },
    };

void main() {
  group('المقاعد المحجوزة تُشتقّ ولا تُقرأ', () {
    test('لا تُقرأ من seats.booked الصفريّة', () {
      expect(TripModel.fromMap(_rideResponse()).seatsBooked, 3,
          reason: 'كان زرّ «عرض الحجوزات (0)» يظهر لسائق رحلة ممتلئة');
    });

    test('السعة ناقص الشاغر', () {
      expect(
          TripModel.fromMap(_rideResponse(capacity: 6, available: 2))
              .seatsBooked,
          4);
    });

    test('الشاغر من الملخّص', () {
      expect(TripModel.fromMap(_rideResponse()).seatsAvailable, 1);
    });

    test('وملخّصٌ مستقلّ عن كتلة الحجوزات يُقرأ كذلك', () {
      final response = Map<String, dynamic>.from(_rideResponse());
      response.remove('bookings');
      response['seat_summary'] = const {
        'total_capacity': 4,
        'available': 1,
      };

      final trip = TripModel.fromMap(response);
      expect(trip.seatsAvailable, 1);
      expect(trip.seatsBooked, 3);
    });

    test('بلا ملخّص إطلاقاً: الشاغر من كتلة المقاعد', () {
      final response = Map<String, dynamic>.from(_rideResponse());
      response.remove('bookings');

      expect(TripModel.fromMap(response).seatsAvailable, 1);
    });
  });

  group('زرّ الحجز — الحالة بوابة الرحلة، والعدّاد بوابة المقعد', () {
    final future = DateTime.now().add(const Duration(days: 1));

    test('full ومعها مقعد شاغر: تُحجز', () {
      expect(
        bookingBlockFor(status: 'full', departure: future, seatsAvailable: 1),
        isNull,
        reason: 'مقعد شغر بإلغاء حجز — والخادم يقبله',
      );
    });

    test('full بلا مقاعد: تُمنع', () {
      expect(
        bookingBlockFor(status: 'full', departure: future, seatsAvailable: 0),
        BookingBlock.full,
      );
    });

    test('مقعد واحد شاغر وطلبُ مقعدين: يُمنع', () {
      expect(
        bookingBlockFor(
            status: 'full',
            departure: future,
            seatsAvailable: 1,
            seatsWanted: 2),
        BookingBlock.full,
      );
    });

    test('عدّاد مجهول: تبقى الحالة وحدها حارساً', () {
      expect(bookingBlockFor(status: 'full', departure: future),
          BookingBlock.full);
    });

    test('active وعدّادها صفر: لا تُمنع هنا بل عند الخادم', () {
      expect(
        bookingBlockFor(
            status: 'active', departure: future, seatsAvailable: 0),
        isNull,
        reason: 'الحالة المعاكسة لا تقع عند الخادم، وعدّادٌ مكسور لا يصحّ '
            'أن يحجب رحلة حيّة',
      );
    });

    test('والملغاة تبقى ممنوعة مهما كانت مقاعدها', () {
      expect(
        bookingBlockFor(
            status: 'cancelled', departure: future, seatsAvailable: 4),
        BookingBlock.cancelled,
      );
    });
  });
}
