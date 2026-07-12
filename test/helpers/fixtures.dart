import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

/// رحلة جاهزة للاختبارات — تُبنى عبر fromMap لتغطية مسار التحويل الحقيقي.
TripModel fakeTrip({int id = 5, int driverId = 3, String status = 'active'}) {
  return TripModel.fromMap({
    'id': id,
    'driver': {'id': driverId, 'name': 'أحمد', 'avatar': null, 'rating': 4},
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
    'status': status,
    'distance': {'meters': 160000, 'kilometers': 160.0},
    'duration': {'seconds': 7200, 'minutes': 120},
    'vehicle_type': 'sedan',
    'payment_method': 'wallet',
    'booking_type': 'instant',
    'notes': null,
    'created_at': '2026-07-01T10:00:00Z',
    'chosen_route_index': 0,
    'communication_number': '0999999999',
    'bookings': [],
  });
}
