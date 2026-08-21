import 'package:alatarekak/core/utils/class/ride_booking_rules.dart';
import 'package:alatarekak/core/utils/class/ride_time_rules.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// إجراءات السائق على رحلته من شاشة التفاصيل.
///
/// عطبان ظهرا في الاستعمال:
///
///   ١. **«عرض الحجوزات (0)»** على رحلة فيها حجوزات — العدد كان يُقرأ من
///      `seats.booked`، وهي صفرٌ دائماً في هذا المسار.
///   ٢. **لا زرّ إلغاء إطلاقاً** في التفاصيل — كان في القائمة وحدها.
Map<String, dynamic> _ride({
  List<Map<String, dynamic>> bookings = const [],
  Map<String, dynamic>? summary,
  String status = 'active',
}) =>
    {
      'success': true,
      'data': {
        'id': 42,
        'driver_id': 5,
        'pickup_address': 'المزة',
        'destination_address': 'درعا',
        'departure_time': '2030-01-01T09:00:00+03:00',
        'available_seats': 1,
        'price_per_seat': 25000,
        'status': status,
        // الكتلة المكسورة: صفرٌ دائماً لأن `loadCount` لا يُستدعى
        'seats': {'available': 1, 'booked': 0, 'total': 1},
      },
      'bookings': {
        'total_bookings': bookings.length,
        if (summary != null) 'seat_summary': summary,
        'list': bookings,
      },
    };

Map<String, dynamic> _booking(int id, String status, int seats) => {
      'id': id,
      'status': status,
      'seats': seats,
      'booked_at': '2026-08-20T09:00:00+00:00',
      'passenger': {'id': id, 'name': 'راكب $id'},
    };

void main() {
  group('عدد الحجوزات على الزرّ', () {
    test('يُقرأ من القائمة لا من seats.booked الصفريّة', () {
      final trip = TripModel.fromMap(_ride(bookings: [
        _booking(1, 'confirmed', 2),
        _booking(2, 'pending', 1),
      ]));

      expect(trip.activeBookingsCount, 2,
          reason: 'حجزان — وكان الزرّ يقول (0)');
    });

    test('والملغاة لا تُعدّ', () {
      final trip = TripModel.fromMap(_ride(bookings: [
        _booking(1, 'confirmed', 2),
        _booking(2, 'cancelled', 1),
        _booking(3, 'no_show', 1),
        _booking(4, 'rejected', 1),
      ]));

      expect(trip.activeBookingsCount, 1,
          reason: 'المسار يرسل كل الحجوزات بما فيها الملغاة');
    });

    test('بلا قائمة: العدّاد المرسَل', () {
      final response = _ride();
      (response['bookings'] as Map)['total_bookings'] = 4;

      expect(TripModel.fromMap(response).activeBookingsCount, 4);
    });

    test('بلا قائمة ولا عدّاد: المقاعد المشتقّة', () {
      final trip = TripModel.fromMap(_ride(
        summary: const {'total_capacity': 4, 'available': 1},
      ));

      expect(trip.activeBookingsCount, 3);
    });

    test('رحلة بلا حجوزات: صفر — والواجهة تُخفي الرقم حينها', () {
      expect(TripModel.fromMap(_ride()).activeBookingsCount, 0);
    });
  });

  group('متى يُعرض زرّ إلغاء الرحلة', () {
    // الشرط: لم تنطلق بعد، ولم تنتهِ ولم تُلغَ. وهو منطق مشترك مع
    // «رحلاتي» — يُقرأ من المصدرين نفسيهما لا من نسخة ثانية.
    bool canCancel(TripModel trip) =>
        RideTimeRules.canCancelRide(trip.departure) &&
        !isRideOver(trip.status);

    test('رحلة قادمة نشطة: يظهر', () {
      expect(canCancel(TripModel.fromMap(_ride())), isTrue);
    });

    test('ورحلة ممتلئة كذلك — الامتلاء ليس انتهاءً', () {
      expect(canCancel(TripModel.fromMap(_ride(status: 'full'))), isTrue);
    });

    test('رحلة منتهية أو ملغاة: لا يظهر', () {
      expect(canCancel(TripModel.fromMap(_ride(status: 'finished'))), isFalse);
      expect(canCancel(TripModel.fromMap(_ride(status: 'cancelled'))), isFalse);
    });

    test('ورحلة انطلقت: لا يظهر', () {
      final departed = _ride();
      (departed['data'] as Map)['departure_time'] =
          '2020-01-01T09:00:00+03:00';

      expect(canCancel(TripModel.fromMap(departed)), isFalse);
    });
  });
}
