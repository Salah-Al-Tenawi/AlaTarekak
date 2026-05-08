import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/maps/data/model/map_info_model.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';

abstract class MapsDataSource {
  final DioConSumer api;

  MapsDataSource({required this.api});
  Future<List<RouteModel>> fetchRouteBYOpenRouteServices(
      LatLng startLocation, LatLng endLocation);
  Future<List<RouteModel>> fetchRouteBYgraphHopper(
      LatLng startLocation, LatLng endLocation);
  Future<String> getPlaceName(LatLng location);
  Future<List<PlaceSuggestion>> searchPlaces(String query);
}

class MapsDataSourceIm extends MapsDataSource {
  final String ghrapHopperApiKey = "a387f47a-e76a-492a-8e1f-275d1d3be3f3";
  final String orsApiKey =
      '5b3ce3597851110001cf62486bcd547ddd63409a97d65b9fc6b02ccd';

  MapsDataSourceIm({required super.api});

  @override
  Future<List<RouteModel>> fetchRouteBYOpenRouteServices(
      LatLng startLocation, LatLng endLocation) async {
    final response = await api.post(
      ApiEndPoint.mapsOpenRouteServices,
      header: {
        ApiKey.authorization: orsApiKey,
      },
      data: {
        ApiKey.coordinates: [
          [startLocation.longitude, startLocation.latitude],
          [endLocation.longitude, endLocation.latitude]
        ],
        ApiKey.alternativeRoutes: {
          ApiKey.targetCount: 3,
          ApiKey.shareFactor: 0.6,
        },
      },
    );

    final features = response[ApiKey.features] as List;

    final List<RouteModel> routes = features
        .map<RouteModel>((feature) => RouteModel.fromOpenRouteServices(feature))
        .toList();

    return routes;
  }

  @override
  Future<List<RouteModel>> fetchRouteBYgraphHopper(
      LatLng startLocation, LatLng endLocation) async {
    final response = await api.get(
      ApiEndPoint.mapsGraphHopper,
      queryParameters: {
        'point': [
          '${startLocation.latitude},${startLocation.longitude}',
          '${endLocation.latitude},${endLocation.longitude}'
        ],
        'vehicle': 'car',
        'locale': 'en',
        'points_encoded': 'false',
        'alternative_route.max_paths': '3',
        'alternative_route.max_weight_factor': '1.6',
        'alternative_route.max_share_factor': '0.8',
        'key': ghrapHopperApiKey,
      },
    );

    final paths = response['paths'] as List;
    return paths
        .map<RouteModel>((path) => RouteModel.fromGraphHopper(path))
        .toList();
  }

    @override
  Future<String> getPlaceName(LatLng location) async {
    final response = await api.get(
      "https://graphhopper.com/api/1/geocode",
      queryParameters: {
        "reverse": "true",
        "point": "${location.latitude},${location.longitude}",
        "locale": "ar", // ممكن تخليها en لو تفضل انجليزي
        "key": ghrapHopperApiKey,
      },
    );

    final hits = response["hits"] as List;
    if (hits.isNotEmpty) {
      final hit = hits[0]; // أقرب نتيجة
      final name = hit["name"] ?? "";
      final street = hit["street"] ?? "";
      final city = hit["city"] ?? "";
      final postcode = hit["postcode"] ?? "";
      final country = hit["country"] ?? "";

      // بناء العنوان بشكل مرتب
      final addressParts = [
        if (name.isNotEmpty) name,
        if (street.isNotEmpty) street,
        if (city.isNotEmpty) city,
        if (postcode.isNotEmpty) postcode,
        if (country.isNotEmpty) country,
      ];

      return addressParts.join(", ");
    } else {
      throw ServerExpcptions(error: Filuar(message: "لم يتم العثور على اسم المكان"));
    }
  }

  @override
  Future<List<PlaceSuggestion>> searchPlaces(String query) async {
    final response = await api.get(
      'https://nominatim.openstreetmap.org/search',
      header: {'User-Agent': 'alatarekak-flutter-app'},
      queryParameters: {
        'q': query,
        'format': 'json',
        'limit': '5',
        'accept-language': 'ar',
        'countrycodes': 'sy',
      },
    );
    final results = response as List;
    return results
        .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
