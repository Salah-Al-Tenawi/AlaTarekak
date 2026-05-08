import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'package:alatarekak/features/maps/data/model/place_suggestion.dart';
import 'package:alatarekak/features/maps/data/repo/map_repo.dart';

part 'pick_location_state.dart';

class PickLocationCubit extends Cubit<PickLocationState> {
  final MapRepoIm mapsRepo;

  PickLocationCubit(this.mapsRepo) : super(PickLocationInitial());

  Future<void> searchByText(String query) async {
    if (query.trim().isEmpty) {
      emit(PickLocationInitial());
      return;
    }
    emit(PickLocationSearchLoading());
    final result = await mapsRepo.searchPlaces(query);
    result.fold(
      (_) => emit(PickLocationInitial()),
      (results) => emit(PickLocationSearchResults(results)),
    );
  }

  void selectSuggestion(PlaceSuggestion suggestion) {
    emit(PickLocationLoaded(
      point: LatLng(suggestion.lat, suggestion.lng),
      placeName: suggestion.displayName,
    ));
  }

  Future<void> selectPoint(LatLng point) async {
    emit(PickLocationLoading(point));

    final result = await mapsRepo.getPlaceName(point);

    result.fold(
      (error) {
        try {
          emit(PickLocationError(
            point: point,
            message: "تعذر جلب اسم المكان 😢",
          ));
        } catch (e) {}
      },
      (name) {
        emit(PickLocationLoaded(
          point: point,
          placeName: name,
        ));
      },
    );
  }
}
