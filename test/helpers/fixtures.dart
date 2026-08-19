import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

/// رحلة جاهزة للاختبارات — تُبنى عبر fromMap لتغطية مسار التحويل الحقيقي.
TripModel fakeTrip({
  int id = 5,
  int driverId = 3,
  String status = 'active',
  String pickup = 'دمشق',
  String destination = 'حمص',
  int seatsAvailable = 3,
}) {
  return TripModel.fromMap({
    'id': id,
    'driver': {'id': driverId, 'name': 'أحمد', 'avatar': null, 'rating': 4},
    'pickup': {
      'address': pickup,
      'coordinates': {'lat': 33.51, 'lng': 36.29},
    },
    'destination': {
      'address': destination,
      'coordinates': {'lat': 34.73, 'lng': 36.71},
    },
    'departure': '2026-07-15T08:00:00Z',
    'seats_available': seatsAvailable,
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

/// حجز جاهز للاختبارات. الافتراضات: حجز مؤكَّد بمقعدين، وموعد انطلاق
/// بعد ثلاث ساعات — أي حجز «قادم» لم تنطلق رحلته بعد.
BookingMe fakeBooking({
  int bookingId = 10,
  String status = 'confirmed',
  int seats = 2,
  int totalPrice = 50000,
  Duration departsIn = const Duration(hours: 3),
  String pickup = 'دمشق',
  String destination = 'حمص',
  String driverName = 'أحمد',
  String driverPhone = '0988888888',
  String myPhone = '0999999999',
  int rideId = 5,
  int userDriver = 3,
}) =>
    BookingMe(
      bookingId: bookingId,
      status: status,
      seats: seats,
      totalPrice: totalPrice,
      bookingDate: DateTime.now().subtract(const Duration(days: 1)),
      passengerCommunicationNumber: myPhone,
      driverCommunicationNumber: driverPhone,
      rideId: rideId,
      pickupAddress: pickup,
      destinationAddress: destination,
      departureTime: DateTime.now().add(departsIn),
      distanceKm: 160,
      durationMinutes: 120,
      pricePerSeat: 25000,
      paymentMethod: 'wallet',
      vehicleType: 'sedan',
      rideStatus: 'active',
      driverName: driverName,
      driverRating: 4.5,
      driverAvatar: '',
      userDriver: userDriver,
    );
