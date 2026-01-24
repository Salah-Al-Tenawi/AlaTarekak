import 'package:latlong2/latlong.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<List<LatLng>> routes;
  final List<Map<String, dynamic>> routeInfos;
  final int currentRouteIndex;
  final LatLng? start;
  final LatLng? end;

  MapLoaded({
    required this.routes,
    required this.routeInfos,
    required this.currentRouteIndex,
    required this.start,
    required this.end,
  });
}

class MapError extends MapState {
  final String message;
  MapError(this.message);
}
