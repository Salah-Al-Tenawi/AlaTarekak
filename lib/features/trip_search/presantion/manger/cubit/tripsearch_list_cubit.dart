import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_search/data/repo/search_repo_im.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'tripsearch_list_state.dart';

class TripsearchListCubit extends SafeCubit<TripsearchListState> {
  TripsearchListCubit(this.repoIm) : super(TripsearchListInitial());
  final SearchRepoIm repoIm;

  // Future showOneTrip(int tripId) async {
  //   emit(TripsearchListLoading());
  //   final response = await repoIm.showOneTrip(tripId);
  //   response.fold((erorr) {
  //     emit(TripsearchListEroor(message: erorr.message));
  //   }, (trip) {
  //     emit(TripsearchListLoaded(trips: trip));
  //   });
  // } 

  
}
