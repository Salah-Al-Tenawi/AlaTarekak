import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

class TripCreateRemoteDataSource {
  final DioConSumer api;

  TripCreateRemoteDataSource({required this.api});

  Future<TripModel> createTrip(
  String startLat,
  String startLng,
  String endLat,
  String endLng,
  String date,
  int seats,
  int price,
  String? notes,
  int routeIndex,
  String paymentMethod,
  String bookingType,
  String communicationNumber,
) async {
  final response = await api.post(
    ApiEndPoint.createRide,
    header: {ApiKey.authorization: "Bearer ${mytoken()}"},
    data: {
      ApiKey.pickuplat: startLat,
      ApiKey.pickuplng: startLng,
      ApiKey.destinationlat: endLat,
      ApiKey.destinationlng: endLng,
      ApiKey.departureTime: date,
      ApiKey.availableSeats: seats,
      ApiKey.pricePerSeat: price,
      ApiKey.notes: notes,
      ApiKey.routeIndex: routeIndex,
      ApiKey.paymentmethod: paymentMethod,
      ApiKey.bookingType: bookingType.toLowerCase(),
      ApiKey.communicationNumber: communicationNumber,
    },
  );

  // من respone.json.data إلى TripModel
  final trip = TripModel.fromJson(response).first;
  return trip;
}

}
