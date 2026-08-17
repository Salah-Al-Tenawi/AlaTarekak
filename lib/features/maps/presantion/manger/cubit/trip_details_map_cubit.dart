import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';
// فيه RouteModel

part 'trip_details_map_state.dart';
class TripDetailsMapCubit extends Cubit<TripDetailsMapState> {
  final MapRepoIm mapRepo;

  TripDetailsMapCubit(this.mapRepo) : super(TripDetailsMapInitial());

  Future<void> fetchRouteByIndex(
      LatLng start, LatLng end, int routeIndex) async {
    emit(TripDetailsMapLoading());

    final result = routeIndex == 0
        ? await mapRepo.fetchRouteBYgraphHopper(start, end)
        : await mapRepo.fetchRouteBYOpenRouteServices(start, end);

    result.fold(
      // خدمات المسار (GraphHopper / OpenRouteService) ترسل أخطاءها
      // بالإنجليزية، وكانت تظهر للمستخدم بنصّها
      (error) => emit(TripDetailsMapError(
          HandelErorrMessage.routeOptions(error.message))),
      (routes) {
        final path = routes.first.path;
        emit(TripDetailsMapLoaded(path));
      },
    );
  }
}
