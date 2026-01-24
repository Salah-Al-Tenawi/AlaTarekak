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

// todo Modleing
  Future<CancelBookingModel> cancelBooking(int bookingId, int seats) async {
    final url = "${ApiEndPoint.baserUrl}/bookings/$bookingId/cancel-seats";

    final response = await _api.post(
      url,
      header: {
        ApiKey.authorization: "Bearer ${mytoken()}",
      },
      data: {
        "seats_to_cancel": seats,
      },
    );

    return response;
  }

  Future<dynamic> finishRide(int bookingid) async {
    final response = await _api.post(
      "${ApiEndPoint.rides}/$bookingid/passenger-confirm",
      header: {
        ApiKey.authorization: "Bearer ${mytoken()}",
      },
    );
    return response;
  }

  Future<CommentModel> addcommit(String commit, int userId) async {
    final response = await _api.post("${ApiEndPoint.profile}/$userId/comments",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"},
        data: {ApiKey.comment: commit});

    return CommentModel.fromJson(response);
  }

  Future<RatingModle> rateUser(double rating, int userId) async {
    final response = await _api.post("${ApiEndPoint.profile}/$userId/rate",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"},
        data: {ApiKey.rating: rating});

    return RatingModle.fromJson(response);
  }
}
