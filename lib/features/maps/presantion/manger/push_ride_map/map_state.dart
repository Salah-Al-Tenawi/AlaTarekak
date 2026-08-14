import 'package:latlong2/latlong.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';

abstract class MapState {}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapLoaded extends MapState {
  final List<List<LatLng>> routes;
  final List<Map<String, dynamic>> routeInfos;
  final int currentRouteIndex;
  final LatLng? start;
  final LatLng? end;
  final String? startName;
  final String? endName;

  /// نقطة مقترحة بانتظار تأكيد المستخدم — يمكنه تحريكها بنقرة أخرى بلا
  /// أي رسم للمسار، فلا يدفع ثمن نقرة خاطئة.
  final LatLng? pending;

  /// هل النقطة المعلّقة للانطلاق (وإلا فهي للوجهة)؟
  final bool pendingIsStart;

  MapLoaded({
    required this.routes,
    required this.routeInfos,
    required this.currentRouteIndex,
    required this.start,
    required this.end,
    this.startName,
    this.endName,
    this.pending,
    this.pendingIsStart = true,
  });
}

class MapError extends MapState {
  final String message;
  MapError(this.message);
}

class MapSearchResults extends MapState {
  final List<PlaceSuggestion> suggestions;
  final bool isForStart;
  MapSearchResults(this.suggestions, {required this.isForStart});
}