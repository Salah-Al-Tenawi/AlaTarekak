import 'package:latlong2/latlong.dart';

class RouteModel {
  final LatLng startPoint;
  final LatLng endPoint;
  final List<LatLng> path;
  final double distance; 
  final double duration; 
  final String serviceUsed; // 'openroute' أو 'graphhopper'

  RouteModel({
    required this.startPoint,
    required this.endPoint,
    required this.path,
    required this.distance,
    required this.duration,
    required this.serviceUsed,
  });

  double get distanceInKm => distance / 1000;
  double get durationInMinutes => duration / 60;

  factory RouteModel.fromOpenRouteServices(Map<String, dynamic> feature) {
    final coords = feature['geometry']['coordinates'] as List;
    final path = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();

    final props = feature['properties']['summary'];
    return RouteModel(
      startPoint: path.first,
      endPoint: path.last,
      path: path,
      distance: (props['distance']??0.0 as num).toDouble() ,
      duration: (props['duration'] as num).toDouble(),
      serviceUsed: 'openroute',
    );
  }

  // Factory method لتحويل JSON من GraphHopper
  factory RouteModel.fromGraphHopper(Map<String, dynamic> pathData) {
    final points = pathData['points']['coordinates'] as List;
    final path = points.map<LatLng>((p) => LatLng(p[1], p[0])).toList();

    return RouteModel(
      startPoint: path.first,
      endPoint: path.last,
      path: path,
      distance: (pathData['distance'] as num).toDouble(),
      duration: (pathData['time'] as num).toDouble() / 1000, 
      serviceUsed: 'graphhopper',
    );
  }

  Map<String, dynamic> toApiMap() {
    return {
      'start_point': {'lat': startPoint.latitude, 'lng': startPoint.longitude},
      'end_point': {'lat': endPoint.latitude, 'lng': endPoint.longitude},
      'path': path.map((point) => {'lat': point.latitude, 'lng': point.longitude}).toList(),
      'distance': distance,
      'duration': duration,
      'service_used': serviceUsed,
      'distance_km': distanceInKm,
      'duration_minutes': durationInMinutes,
    };
  }
}