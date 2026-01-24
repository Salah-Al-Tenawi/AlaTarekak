import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/features/maps/data/data_source/maps_data_source.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  MapCubit() : super(MapInitial()) {
    mapsRepo = MapRepoIm(
      mapsDataSource: MapsDataSourceIm(api: DioConSumer()),
    );
  }

  late MapRepoIm mapsRepo;

  LatLng? startLocation;
  LatLng? endLocation;
  List<List<LatLng>> allRoutes = [];
  List<Map<String, dynamic>> routeInfos = [];
  int currentRouteIndex = 0;

  void tapOnMap(LatLng point) async {
    if (startLocation == null) {
      startLocation = point;
      endLocation = null;
      allRoutes = [];
      routeInfos = [];

      emit(MapLoaded(
        routes: [],
        routeInfos: [],
        currentRouteIndex: 0,
        start: startLocation,
        end: endLocation,
      ));
      return;
    }

    if (endLocation == null) {
      endLocation = point;

      emit(MapLoaded(
        routes: [],
        routeInfos: [],
        currentRouteIndex: 0,
        start: startLocation,
        end: endLocation,
      ));

      emit(MapLoading());

      final double distance = _calculateDistance(startLocation!, endLocation!);
      final bool useOpenRoute = distance < 100;

      final response = useOpenRoute
          ? await mapsRepo.fetchRouteBYOpenRouteServices(
              startLocation!, endLocation!)
          : await mapsRepo.fetchRouteBYgraphHopper(
              startLocation!, endLocation!);

      response.fold(
        (failure) => emit(MapError(failure.message)),
        (routes) {
          if (routes.isEmpty) {
            emit(MapError("لم يتم العثور على مسارات."));
          } else {
            allRoutes = routes.map((e) => e.path).toList();
            routeInfos = routes
                .map((e) => {
                      "distance": e.distance,
                      "duration": e.duration,
                    })
                .toList();
            currentRouteIndex = 0;

            emit(MapLoaded(
              routes: allRoutes,
              routeInfos: routeInfos,
              currentRouteIndex: currentRouteIndex,
              start: startLocation,
              end: endLocation,
            ));
          }
        },
      );
      return;
    }

    startLocation = point;
    endLocation = null;
    allRoutes = [];
    routeInfos = [];

    emit(MapLoaded(
      routes: [],
      routeInfos: [],
      currentRouteIndex: 0,
      start: startLocation,
      end: endLocation,
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
      ));
    }
    return currentRouteIndex;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const Distance distance = Distance();
    return distance(start, end) / 1000;
  } 




  
}
