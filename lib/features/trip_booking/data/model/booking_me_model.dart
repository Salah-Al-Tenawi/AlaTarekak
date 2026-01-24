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

  factory BookingMe.fromJson(Map<String, dynamic> json) {
    return BookingMe(
      userDriver: json['driver_id'],
      bookingId: json['booking_id'] ?? 0,
      status: json['status'] ?? "",
      seats: json['seats'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
      bookingDate:
          DateTime.tryParse(json['booking_date'] ?? "") ?? DateTime.now(),
      passengerCommunicationNumber:
          json['passenger_communication_number'] ?? "",
      driverCommunicationNumber: json['driver_communication_number'] ?? "",
      rideId: json['ride_id'] ?? 0,
      pickupAddress: json['pickup_address'] ?? "",
      destinationAddress: json['destination_address'] ?? "",
      departureTime: DateTime.parse(json['departure_time'] ?? "").toLocal(),
      distanceKm: (json['distance_km'] is num)
          ? (json['distance_km'] as num).toDouble()
          : 0.0,
      durationMinutes: json['duration_minutes'] ?? 0,
      pricePerSeat: (json['price_per_seat'] is num)
          ? (json['price_per_seat'] as num).toDouble()
          : double.tryParse(json['price_per_seat']?.toString() ?? "0") ?? 0.0,
      paymentMethod: json['payment_method'] ?? "",
      vehicleType: json['vehicle_type'] ?? "",
      rideStatus: json['ride_status'] ?? "",
      driverName: json['driver_name'] ?? "",
      driverRating: (json['driver_rating'] is num)
          ? (json['driver_rating'] as num).toDouble()
          : 0.0,
      driverAvatar: json['driver_avatar'] ?? "",
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
