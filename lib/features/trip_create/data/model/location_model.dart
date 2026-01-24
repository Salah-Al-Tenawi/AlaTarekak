
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
      address: json['address'],
      coordinates: CoordinatesModel.fromJson(json['coordinates']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'coordinates': coordinates.toJson(),
    };
  }
}
