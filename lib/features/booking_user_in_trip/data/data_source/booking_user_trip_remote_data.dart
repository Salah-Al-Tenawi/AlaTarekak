import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/model/booking_user_modle.dart';

class BookingUserTripRemoteData {
  final ApiConSumer api;

  BookingUserTripRemoteData({required this.api});
  Future<BookingUserModle> acceptPassanger(int bookingId) async {
    final response = await api.post(
        "${ApiEndPoint.bookings}/$bookingId/accept",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return BookingUserModle.fromJson(response);
  }

  Future<dynamic> rejectPassanger(int bookingId) async {
    final response = await api.post(
        "${ApiEndPoint.bookings}/$bookingId/reject",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});

    return response;
  }

  /// بلاغ السائق أن الراكب لم يحضر — POST /bookings/{id}/passenger-no-show
  Future<dynamic> passengerNoShow(int bookingId) async {
    final response = await api.post(
        "${ApiEndPoint.bookings}/$bookingId/passenger-no-show",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return response;
  }
}
