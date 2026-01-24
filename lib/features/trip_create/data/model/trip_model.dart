import 'package:alatarekak/features/trip_create/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_create/data/model/distan_model.dart';
import 'package:alatarekak/features/trip_create/data/model/driver_model.dart';
import 'package:alatarekak/features/trip_create/data/model/duration_model.dart';
import 'package:alatarekak/features/trip_create/data/model/location_model.dart';

class TripModel {
  final int id;
  final DriverModel driver;
  final LocationModel pickup;
  final LocationModel destination;
  final DateTime departure;
  final int seatsAvailable;
  final int seatsBooked;
  final String pricePerSeat;
  final String status;
  final DistanceModel distance;
  final DurationInfoModel duration;
  final String vehicleType;
  final String paymentMethod;
  final String bookingType;
  final String? notes;
  final DateTime createdAt;
  final int chosenRouteIndex;
  final String communicationNumber;
  final List<BookingModel> booking;

  TripModel({
    required this.id,
    required this.driver,
    required this.pickup,
    required this.destination,
    required this.departure,
    required this.seatsAvailable,
    required this.seatsBooked,
    required this.pricePerSeat,
    required this.status,
    required this.distance,
    required this.duration,
    required this.vehicleType,
    required this.paymentMethod,
    required this.bookingType,
    required this.notes,
    required this.createdAt,
    required this.chosenRouteIndex,
    required this.communicationNumber,
    required this.booking,
  });

  /// لتحويل JSON كائن رحلة واحدة
  factory TripModel.fromMap(Map<String, dynamic> json) {
    // إذا الرد ملفوف بـ { data: {...} } خذ الداخل، وإلا استخدم json نفسه
    final data =
        (json['data'] is Map) ? Map<String, dynamic>.from(json['data']) : json;

    return TripModel(
      id: data['id'],
      driver: DriverModel.fromJson(data['driver']),
      pickup: LocationModel.fromJson(data['pickup']),
      destination: LocationModel.fromJson(data['destination']),
      departure: DateTime.parse(data['departure']).toLocal(),
      seatsAvailable: data['seats_available'],
      seatsBooked: data['seats_booked'],
      pricePerSeat: data['price_per_seat'],
      status: data['status'],
      distance: DistanceModel.fromJson(data['distance']),
      duration: DurationInfoModel.fromJson(data['duration']),
      vehicleType: data['vehicle_type'],
      paymentMethod: data['payment_method'],
      bookingType: data['booking_type'],
      notes: data['notes'],
      createdAt: DateTime.parse(data['created_at']),
      chosenRouteIndex: data['chosen_route_index'],
      communicationNumber: data['communication_number'],
      booking: (data['bookings'] as List?)
              ?.map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static List<TripModel> fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final body = json['data'] ?? json; // يدعم وجود/عدم وجود data
      if (body is List) {
        return body
            .map((e) => TripModel.fromMap(e as Map<String, dynamic>))
            .toList();
      } else if (body is Map<String, dynamic>) {
        return [TripModel.fromMap(body)];
      }
    } else if (json is List) {
      return json
          .map((e) => TripModel.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception("صيغة JSON غير مدعومة");
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'driver': driver.toJson(),
      'pickup': pickup.toJson(),
      'destination': destination.toJson(),
      'departure': departure.toIso8601String(),
      'seats_available': seatsAvailable,
      'seats_booked': seatsBooked,
      'price_per_seat': pricePerSeat,
      'status': status,
      'distance': distance.toJson(),
      'duration': duration.toJson(),
      'vehicle_type': vehicleType,
      'payment_method': paymentMethod,
      'booking_type': bookingType,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'chosen_route_index': chosenRouteIndex,
      'communication_number': communicationNumber,
    };
  }
}
