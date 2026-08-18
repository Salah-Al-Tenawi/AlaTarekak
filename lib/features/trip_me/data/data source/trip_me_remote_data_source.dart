import 'package:alatarekak/core/api/api_consumer.dart';
import 'package:alatarekak/core/api/api_end_points.dart';

import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

class TripMeRemoteDataSource {
  final ApiConSumer api;

  TripMeRemoteDataSource({required this.api});
  Future<List<TripModel>> getMyTrip() async {
    final response = await api.get(
      ApiEndPoint.rides,
      header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    );

    final List<TripModel> trips = TripModel.fromJson(response);
    return trips;
  }

  // showOneTrip حُذف: كان يستدعي `/rides/{id}/passangers` ولا يناديه
  // أحد، بينما تجلب شاشة التفاصيل من `/rides/{id}` فتأتي بلا حجوزات.
  // صار المسار يُستدعى من `TripDetailsRepoIM.featchTripWithBookings`.

  Future<dynamic> cancelTrip(int tripId) async {
    final response = await api.patch("${ApiEndPoint.rides}/$tripId/cancel",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return response;
  }

}
