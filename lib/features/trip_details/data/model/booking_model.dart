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

  /// من ride.driver — يُستخدمان لعنوان محادثة السائق بعد الحجز
  final String? driverName;
  final String? driverAvatar;

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
    this.driverName,
    this.driverAvatar,
  });

  /// الحجز مؤكَّد فعلاً (رحلة direct) لا بانتظار موافقة السائق
  bool get isConfirmed => status == 'confirmed';

  /// يدعم شكل BookingResource المتداخل (passenger/ride/driver) والشكل القديم
  factory BookingData.fromJson(Map<String, dynamic> json) {
    final ride = json['ride'] is Map<String, dynamic>
        ? json['ride'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final driver = ride['driver'] is Map<String, dynamic>
        ? ride['driver'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final passenger = json['passenger'] is Map<String, dynamic>
        ? json['passenger'] as Map<String, dynamic>
        : const <String, dynamic>{};

    int toInt(dynamic v) =>
        v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

    return BookingData(
      id: toInt(json['id']),
      rideId: toInt(json['ride_id'] ?? ride['id']),
      driverId: toInt(json['driver_id'] ?? driver['id']),
      passengerId: toInt(json['passenger_id'] ?? passenger['id']),
      seats: toInt(json['seats']),
      status: json['status']?.toString() ?? '',
      communicationNumber: json['communication_number']?.toString() ?? '',
      totalPrice: toInt(json['total_price']),
      bookingDate: DateTime.tryParse(
              (json['booking_date'] ?? json['created_at'] ?? '').toString()) ??
          DateTime.now(),
      rideDetails: json['ride_details'] != null
          ? RideDetails.fromJson(json['ride_details'])
          : (ride.isNotEmpty ? RideDetails.fromJson(ride) : null),
      driverName: driver['name']?.toString(),
      driverAvatar: driver['avatar']?.toString(),
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
      pickupAddress: json['pickup_address']?.toString() ?? '',
      destinationAddress: json['destination_address']?.toString() ?? '',
      departureTime:
          DateTime.tryParse((json['departure_time'] ?? '').toString()) ??
              DateTime.now(),
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
