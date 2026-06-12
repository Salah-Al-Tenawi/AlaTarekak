import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit(this.mapsRepo) : super(MapInitial());

  final MapRepoIm mapsRepo;

  LatLng? startLocation;
  LatLng? endLocation;
  String? startPlaceName;
  String? endPlaceName;
  List<List<LatLng>> allRoutes = [];
  List<Map<String, dynamic>> routeInfos = [];
  int currentRouteIndex = 0;
  bool _searchingForStart = true;

  void setSearchMode(bool forStart) {
    _searchingForStart = forStart;
  }

  Future<void> searchPlaces(String query) async {
    if (query.trim().length < 2) return;
    final result = await mapsRepo.searchPlaces(query);
    result.fold(
      (_) {},
      (suggestions) =>
          emit(MapSearchResults(suggestions, isForStart: _searchingForStart)),
    );
  }

  void selectFromSearch(PlaceSuggestion place) {
    final point = LatLng(place.lat, place.lng);
    if (_searchingForStart) {
      startLocation = point;
      startPlaceName = place.displayName;
      endLocation = null;
      allRoutes = [];
      routeInfos = [];
      emit(MapLoaded(
        routes: const [],
        routeInfos: const [],
        currentRouteIndex: 0,
        start: startLocation,
        end: null,
        startName: startPlaceName,
      ));
    } else {
      endLocation = point;
      endPlaceName = place.displayName;
      _fetchRoutes();
    }
  }

  void tapOnMap(LatLng point) {
    if (startLocation == null) {
      startLocation = point;
      endLocation = null;
      allRoutes = [];
      routeInfos = [];
      emit(MapLoaded(
        routes: const [],
        routeInfos: const [],
        currentRouteIndex: 0,
        start: startLocation,
        end: null,
      ));
      return;
    }

    if (endLocation == null) {
      endLocation = point;
      emit(MapLoaded(
        routes: const [],
        routeInfos: const [],
        currentRouteIndex: 0,
        start: startLocation,
        end: endLocation,
      ));
      _fetchRoutes();
      return;
    }

    startLocation = point;
    endLocation = null;
    startPlaceName = null;
    endPlaceName = null;
    allRoutes = [];
    routeInfos = [];
    emit(MapLoaded(
      routes: const [],
      routeInfos: const [],
      currentRouteIndex: 0,
      start: startLocation,
      end: null,
    ));
  }

  int switchRoute() {
    if (allRoutes.length > 1) {
      currentRouteIndex = (currentRouteIndex + 1) % allRoutes.length;
      emit(MapLoaded(
        routes: allRoutes,
        routeInfos: routeInfos,
        currentRouteIndex: currentRouteIndex,
        start: startLocation,
        end: endLocation,
        startName: startPlaceName,
        endName: endPlaceName,
      ));
    }
    return currentRouteIndex;
  }

  void resetAll() {
    startLocation = null;
    endLocation = null;
    startPlaceName = null;
    endPlaceName = null;
    allRoutes = [];
    routeInfos = [];
    currentRouteIndex = 0;
    emit(MapInitial());
  }

  Future<void> _fetchRoutes() async {
    emit(MapLoading());

    // Resolve names for tap-placed pins (no name from search)
    final futures = <Future>[];
    if (startPlaceName == null && startLocation != null) {
      futures.add(mapsRepo
          .getPlaceName(startLocation!)
          .then((r) => r.fold((_) {}, (n) => startPlaceName = n)));
    }
    if (endPlaceName == null && endLocation != null) {
      futures.add(mapsRepo
          .getPlaceName(endLocation!)
          .then((r) => r.fold((_) {}, (n) => endPlaceName = n)));
    }
    if (futures.isNotEmpty) await Future.wait(futures);

    final double dist = _calcDistanceKm(startLocation!, endLocation!);
    final response = dist < 100
        ? await mapsRepo.fetchRouteBYOpenRouteServices(
            startLocation!, endLocation!)
        : await mapsRepo.fetchRouteBYgraphHopper(
            startLocation!, endLocation!);

    response.fold(
      (failure) => emit(MapError(failure.message)),
      (routes) {
        if (routes.isEmpty) {
          emit(MapError("لم يتم العثور على مسارات"));
        } else {
          allRoutes = routes.map((r) => r.path).toList();
          routeInfos = routes
              .map((r) => {'distance': r.distance, 'duration': r.duration})
              .toList();
          currentRouteIndex = 0;
          emit(MapLoaded(
            routes: allRoutes,
            routeInfos: routeInfos,
            currentRouteIndex: 0,
            start: startLocation,
            end: endLocation,
            startName: startPlaceName,
            endName: endPlaceName,
          ));
        }
      },
    );
  }

  double _calcDistanceKm(LatLng a, LatLng b) {
    const Distance d = Distance();
    return d(a, b) / 1000;
  }
}
