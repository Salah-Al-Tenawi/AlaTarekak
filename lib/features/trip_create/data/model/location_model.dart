import 'package:alatarekak/core/utils/functions/json_parse.dart';
import 'package:alatarekak/features/trip_create/data/model/coordinates_model.dart';

class LocationModel {
  final String address;
  final CoordinatesModel coordinates;

  LocationModel({
    required this.address,
    required this.coordinates,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      address: asString(json['address']) ?? '',
      coordinates: CoordinatesModel.fromAny(json['coordinates'],
          lat: json['lat'], lng: json['lng']),
    );
  }

  /// يقرأ الموقع من الرحلة بأيّ من شكليها:
  ///
  /// * محوَّل: `pickup: {address, coordinates: {lat, lng}}`
  /// * خام:   `pickup_address` + `pickup_location: {lat, lng}` أو
  ///          `pickup_lat` / `pickup_lng`
  ///
  /// [prefix] هو `pickup` أو `destination`.
  factory LocationModel.fromTrip(Map<String, dynamic> trip, String prefix) {
    final nested = asMap(trip[prefix]);
    if (nested != null) return LocationModel.fromJson(nested);

    return LocationModel(
      address: asString(trip['${prefix}_address']) ?? '',
      coordinates: CoordinatesModel.fromAny(
        trip['${prefix}_location'],
        lat: trip['${prefix}_lat'],
        lng: trip['${prefix}_lng'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': coordinates.toJson(),
    };
  }
}
