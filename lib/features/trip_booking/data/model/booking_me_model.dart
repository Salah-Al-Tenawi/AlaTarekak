import 'dart:convert';

class BookingMeModel {
  final bool success;
  final List<BookingMe> data;

  BookingMeModel({
    required this.success,
    required this.data,
  });

  factory BookingMeModel.fromJson(Map<String, dynamic> json) {
    return BookingMeModel(
      success: json['success'] ?? false,
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => BookingMe.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "success": success,
      "data": data.map((e) => e.toJson()).toList(),
    };
  }
}

class BookingMe {
  final int userDriver;
  final int bookingId;
  final String status;
  final int seats;
  final int totalPrice;
  final DateTime bookingDate;
  final String passengerCommunicationNumber;
  final String driverCommunicationNumber;
  final int rideId;
  final String pickupAddress;
  final String destinationAddress;
  final DateTime departureTime;
  final double distanceKm;
  final int durationMinutes;
  final double pricePerSeat;
  final String paymentMethod;
  final String vehicleType;
  final String rideStatus;
  final String driverName;
  final double driverRating;
  final String driverAvatar;

  BookingMe({
    required this.bookingId,
    required this.status,
    required this.seats,
    required this.totalPrice,
    required this.bookingDate,
    required this.passengerCommunicationNumber,
    required this.driverCommunicationNumber,
    required this.rideId,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.departureTime,
    required this.distanceKm,
    required this.durationMinutes,
    required this.pricePerSeat,
    required this.paymentMethod,
    required this.vehicleType,
    required this.rideStatus,
    required this.driverName,
    required this.driverRating,
    required this.driverAvatar,
    required this.userDriver,
  });

  /// يدعم شكلين: BookingResource المتداخل (GET /bookings الحالي:
  /// ride{driver{...}}) والشكل المسطّح القديم من /my-bookings.
  factory BookingMe.fromJson(Map<String, dynamic> json) {
    final ride =
        json['ride'] is Map<String, dynamic> ? json['ride'] as Map<String, dynamic> : const <String, dynamic>{};
    final driver = ride['driver'] is Map<String, dynamic>
        ? ride['driver'] as Map<String, dynamic>
        : const <String, dynamic>{};

    double toDouble(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    int toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;
    DateTime? toDate(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

    return BookingMe(
      userDriver: toInt(json['driver_id'] ?? driver['id']),
      bookingId: toInt(json['booking_id'] ?? json['id']),
      status: json['status']?.toString() ?? "",
      seats: toInt(json['seats']),
      totalPrice: toInt(json['total_price']),
      bookingDate:
          toDate(json['booking_date'] ?? json['created_at']) ?? DateTime.now(),
      passengerCommunicationNumber:
          (json['passenger_communication_number'] ??
                  json['communication_number'] ??
                  "")
              .toString(),
      driverCommunicationNumber: (json['driver_communication_number'] ??
              driver['communication_number'] ??
              "")
          .toString(),
      rideId: toInt(json['ride_id'] ?? ride['id']),
      pickupAddress:
          (json['pickup_address'] ?? ride['pickup_address'] ?? "").toString(),
      destinationAddress: (json['destination_address'] ??
              ride['destination_address'] ??
              "")
          .toString(),
      departureTime:
          toDate(json['departure_time'] ?? ride['departure_time']) ??
              DateTime.now(),
      distanceKm: toDouble(json['distance_km'] ?? ride['distance_km']),
      durationMinutes:
          toInt(json['duration_minutes'] ?? ride['duration_minutes']),
      pricePerSeat:
          toDouble(json['price_per_seat'] ?? ride['price_per_seat']),
      paymentMethod:
          (json['payment_method'] ?? ride['payment_method'] ?? "").toString(),
      vehicleType:
          (json['vehicle_type'] ?? ride['vehicle_type'] ?? "").toString(),
      rideStatus:
          (json['ride_status'] ?? ride['status'] ?? "").toString(),
      driverName: (json['driver_name'] ?? driver['name'] ?? "").toString(),
      driverRating: toDouble(json['driver_rating'] ?? driver['rating']),
      driverAvatar:
          (json['driver_avatar'] ?? driver['avatar'] ?? "").toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "booking_id": bookingId,
      "status": status,
      "seats": seats,
      "total_price": totalPrice,
      "booking_date": bookingDate.toIso8601String(),
      "passenger_communication_number": passengerCommunicationNumber,
      "driver_communication_number": driverCommunicationNumber,
      "ride_id": rideId,
      "pickup_address": pickupAddress,
      "destination_address": destinationAddress,
      "departure_time": departureTime.toIso8601String(),
      "distance_km": distanceKm,
      "duration_minutes": durationMinutes,
      "price_per_seat": pricePerSeat,
      "payment_method": paymentMethod,
      "vehicle_type": vehicleType,
      "ride_status": rideStatus,
      "driver_name": driverName,
      "driver_rating": driverRating,
      "driver_avatar": driverAvatar,
    };
  }
}

/// تحويل سريع من JSON String إلى BookingMeModel
BookingMeModel bookingMeModelFromJson(String str) =>
    BookingMeModel.fromJson(json.decode(str));

/// تحويل من BookingMeModel إلى JSON String
String bookingMeModelToJson(BookingMeModel data) => json.encode(data.toJson());
