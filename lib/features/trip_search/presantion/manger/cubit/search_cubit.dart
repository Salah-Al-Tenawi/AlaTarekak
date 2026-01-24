import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_search/data/repo/search_repo_im.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepoIm repoIm;
  SearchCubit(this.repoIm) : super(SearchInitial());

  search(String sourcelat, String sourcelng, String destlat, String destlng,
      String departureDate, int seatsRequired) async {
    emit(SearchLoading());
    final response = await repoIm.search(
        sourcelat, sourcelng, destlat, destlng, departureDate, seatsRequired);

    response.fold((erorr) {
      emit(SearchErorr(error: erorr.message));
    }, (listTrip) {
      emit(SearchSucces(trips: listTrip));
    });
  }
}
