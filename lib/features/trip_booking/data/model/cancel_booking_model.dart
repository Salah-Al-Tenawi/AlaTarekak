class CancelBookingModel {
  final bool success;
  final String message;
  final CancelBookingData data;

  CancelBookingModel({
    required this.success,
    required this.message,
    required this.data,
  });

  factory CancelBookingModel.fromJson(Map<String, dynamic> json) {
    // الباك إند يرجع هنا {"status": "success"} وليس {"success": true}
    return CancelBookingModel(
      success: json['success'] == true || json['status'] == 'success',
      message: json['message']?.toString() ?? '',
      data: CancelBookingData.fromJson(
          json['data'] is Map<String, dynamic> ? json['data'] : const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data.toJson(),
    };
  }
}

class CancelBookingData {
  final int bookingId;
  final int seatsCancelled;
  final int remainingSeats;
  final RefundPolicy refundPolicy;
  final String bookingStatus;

  CancelBookingData({
    required this.bookingId,
    required this.seatsCancelled,
    required this.remainingSeats,
    required this.refundPolicy,
    required this.bookingStatus,
  });

  factory CancelBookingData.fromJson(Map<String, dynamic> json) {
    return CancelBookingData(
      bookingId: (json['booking_id'] as num?)?.toInt() ?? 0,
      seatsCancelled: (json['seats_cancelled'] as num?)?.toInt() ?? 0,
      remainingSeats: (json['remaining_seats'] as num?)?.toInt() ?? 0,
      refundPolicy: RefundPolicy.fromJson(
          json['refund_policy'] is Map<String, dynamic>
              ? json['refund_policy']
              : const {}),
      bookingStatus: json['booking_status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'booking_id': bookingId,
      'seats_cancelled': seatsCancelled,
      'remaining_seats': remainingSeats,
      'refund_policy': refundPolicy.toJson(),
      'booking_status': bookingStatus,
    };
  }
}

class RefundPolicy {
  final double timeElapsedPercentage;
  final double refundPercentage;
  final String policyTier;
  final double totalSeatPrice;
  final double refundAmount;
  final double nonRefundableAmount;
  final bool refundProcessed;

  RefundPolicy({
    required this.timeElapsedPercentage,
    required this.refundPercentage,
    required this.policyTier,
    required this.totalSeatPrice,
    required this.refundAmount,
    required this.nonRefundableAmount,
    required this.refundProcessed,
  });

  factory RefundPolicy.fromJson(Map<String, dynamic> json) {
    return RefundPolicy(
      timeElapsedPercentage:
          (json['time_elapsed_percentage'] as num?)?.toDouble() ?? 0,
      refundPercentage: (json['refund_percentage'] as num?)?.toDouble() ?? 0,
      policyTier: json['policy_tier']?.toString() ?? '',
      totalSeatPrice: (json['total_seat_price'] as num?)?.toDouble() ?? 0,
      refundAmount: (json['refund_amount'] as num?)?.toDouble() ?? 0,
      nonRefundableAmount:
          (json['non_refundable_amount'] as num?)?.toDouble() ?? 0,
      refundProcessed: json['refund_processed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time_elapsed_percentage': timeElapsedPercentage,
      'refund_percentage': refundPercentage,
      'policy_tier': policyTier,
      'total_seat_price': totalSeatPrice,
      'refund_amount': refundAmount,
      'non_refundable_amount': nonRefundableAmount,
      'refund_processed': refundProcessed,
    };
  }
}
