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

  Future<TripModel> showOneTrip(int tripId) async {
    final response = await api.get("${ApiEndPoint.rides}/$tripId",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});

    return TripModel.fromMap(response);
  }

  Future<dynamic> cancelTrip(int tripId) async {
    final response = await api.patch("${ApiEndPoint.rides}/$tripId/cancel",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});
    return response;
  }

}
