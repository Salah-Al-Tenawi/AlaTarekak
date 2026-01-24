import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/model/booking_user_modle.dart';

class BookingUserTripRemoteData {
  final ApiConSumer api;

  BookingUserTripRemoteData({required this.api});
  Future<BookingUserModle> acceptPassanger(int bookingId) async {
    final response = await api.post("${ApiEndPoint.rides}/$bookingId/accept",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return BookingUserModle.fromJson(response);
  }

  Future<dynamic> rejectPassanger(int bookingId) async {
    final response = await api.post("${ApiEndPoint.rides}/$bookingId/reject",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});

    return response;
  }
}
