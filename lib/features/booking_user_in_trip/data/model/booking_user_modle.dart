import 'package:alatarekak/core/api/api_end_points.dart';

class BookingUserModle {
  final String message;
  final bool payment;
  final String statusRide;

  BookingUserModle(
      {required this.message, required this.payment, required this.statusRide});

  factory BookingUserModle.fromJson(Map<String, dynamic> json) {
    return BookingUserModle(
        message: json[ApiKey.message],
        payment: json['payment_processed'],
        statusRide: json['ride_status']);
  }
}
