class BookingResponse {
  final bool success;
  final BookingData? data;
  final String? message;
  final dynamic paymentInfo; 

  BookingResponse({
    required this.success,
    this.data,
    this.message,
    this.paymentInfo,
  });

  factory BookingResponse.fromJson(Map<String, dynamic> json) {
    return BookingResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? BookingData.fromJson(json['data']) : null,
      message: json['message'],
      paymentInfo: json['payment_info'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
      'message': message,
      'payment_info': paymentInfo,
    };
  }
}

class BookingData {
  final int id;
  final int rideId;
  final int driverId;
  final int passengerId;
  final int seats;
  final String status;
  final String communicationNumber;
  final int totalPrice;
  final DateTime bookingDate;
  final RideDetails? rideDetails;

  BookingData({
    required this.id,
    required this.rideId,
    required this.driverId,
    required this.passengerId,
    required this.seats,
    required this.status,
    required this.communicationNumber,
    required this.totalPrice,
    required this.bookingDate,
    this.rideDetails,
  });

  factory BookingData.fromJson(Map<String, dynamic> json) {
    return BookingData(
      id: json['id'],
      rideId: json['ride_id'],
      driverId: json['driver_id'],
      passengerId: json['passenger_id'],
      seats: json['seats'],
      status: json['status'],
      communicationNumber: json['communication_number'],
      totalPrice: json['total_price'],
      bookingDate: DateTime.parse(json['booking_date']),
      rideDetails: json['ride_details'] != null
          ? RideDetails.fromJson(json['ride_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ride_id': rideId,
      'driver_id': driverId,
      'passenger_id': passengerId,
      'seats': seats,
      'status': status,
      'communication_number': communicationNumber,
      'total_price': totalPrice,
      'booking_date': bookingDate.toIso8601String(),
      'ride_details': rideDetails?.toJson(),
    };
  }
}

class RideDetails {
  final String pickupAddress;
  final String destinationAddress;
  final DateTime departureTime;

  RideDetails({
    required this.pickupAddress,
    required this.destinationAddress,
    required this.departureTime,
  });

  factory RideDetails.fromJson(Map<String, dynamic> json) {
    return RideDetails(
      pickupAddress: json['pickup_address'],
      destinationAddress: json['destination_address'],
      departureTime: DateTime.parse(json['departure_time']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pickup_address': pickupAddress,
      'destination_address': destinationAddress,
      'departure_time': departureTime.toIso8601String(),
    };
  }
}
