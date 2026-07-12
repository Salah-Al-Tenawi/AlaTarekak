import 'package:alatarekak/core/api/api_end_points.dart';

class BookingUserModle {
  final String message;
  final bool payment;
  final String statusRide;

  BookingUserModle(
      {required this.message, required this.payment, required this.statusRide});

  /// استجابة accept الحالية: {success, data: BookingResource, message}
  /// — الحقول القديمة payment_processed/ride_status قد لا تكون موجودة
  factory BookingUserModle.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return BookingUserModle(
        message: json[ApiKey.message]?.toString() ?? '',
        payment: json['payment_processed'] == true,
        statusRide:
            (json['ride_status'] ?? data['status'] ?? '').toString());
  }
}
