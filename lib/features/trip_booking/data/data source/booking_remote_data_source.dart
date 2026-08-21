import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/profiles/data/model/comment_model.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/data/model/cancel_booking_model.dart';

class BookingRemoteDataSource {
  final ApiConSumer _api;

  BookingRemoteDataSource({required ApiConSumer api}) : _api = api;
  Future<List<BookingMe>> getMeBooking() async {
    final response = await _api.get(
      ApiEndPoint.bookingme,
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );

    final bookingModel = BookingMeModel.fromJson(response);
    return bookingModel.data;
  }

  /// إلغاء جزء من المقاعد — POST /bookings/{id}/cancel-seats
  Future<CancelBookingModel> cancelBooking(int bookingId, int seats) async {
    final url = "${ApiEndPoint.bookings}/$bookingId/cancel-seats";

    final response = await _api.post(
      url,
      header: {
        ApiKey.authorization: "Bearer ${mytoken()}",
      },
      data: {
        "seats_to_cancel": seats,
      },
    );

    return CancelBookingModel.fromJson(response as Map<String, dynamic>);
  }

  /// إلغاء الحجز بالكامل — POST /bookings/{id}/cancel
  Future<dynamic> cancelWholeBooking(int bookingId) async {
    final response = await _api.post(
      "${ApiEndPoint.bookings}/$bookingId/cancel",
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );
    return response;
  }

  /// تأكيد الراكب لاكتمال الرحلة — POST /bookings/{id}/passenger-confirm
  Future<dynamic> finishRide(int bookingid) async {
    final response = await _api.post(
      "${ApiEndPoint.bookings}/$bookingid/passenger-confirm",
      header: {
        ApiKey.authorization: "Bearer ${mytoken()}",
      },
    );
    return response;
  }

  /// بلاغ الراكب أن السائق لم يحضر — POST /rides/{rideId}/driver-no-show
  Future<dynamic> driverNoShow(int rideId) async {
    final response = await _api.post(
      "${ApiEndPoint.rides}/$rideId/driver-no-show",
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );
    return response;
  }

  /// **`ride_id` شرطٌ في الجسم** — انظر نظيرتها في جانب السائق.
  Future<CommentModel> addcommit(
      String commit, int userId, int rideId) async {
    final response = await _api.post("${ApiEndPoint.profile}/$userId/comments",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"},
        data: {ApiKey.comment: commit, ApiKey.rideId: rideId});

    return CommentModel.fromJson(response);
  }

  Future<RatingModle> rateUser(double rating, int userId, int rideId) async {
    final response = await _api.post("${ApiEndPoint.profile}/$userId/rate",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"},
        data: {ApiKey.rating: rating, ApiKey.rideId: rideId});

    return RatingModle.fromJson(response);
  }
}
