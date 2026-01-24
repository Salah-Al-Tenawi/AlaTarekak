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
    return CancelBookingModel(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: CancelBookingData.fromJson(json['data']),
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
      bookingId: json['booking_id'] as int,
      seatsCancelled: json['seats_cancelled'] as int,
      remainingSeats: json['remaining_seats'] as int,
      refundPolicy: RefundPolicy.fromJson(json['refund_policy']),
      bookingStatus: json['booking_status'] as String,
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
      timeElapsedPercentage: (json['time_elapsed_percentage'] as num).toDouble(),
      refundPercentage: (json['refund_percentage'] as num).toDouble(),
      policyTier: json['policy_tier'] as String,
      totalSeatPrice: (json['total_seat_price'] as num).toDouble(),
      refundAmount: (json['refund_amount'] as num).toDouble(),
      nonRefundableAmount: (json['non_refundable_amount'] as num).toDouble(),
      refundProcessed: json['refund_processed'] as bool,
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
