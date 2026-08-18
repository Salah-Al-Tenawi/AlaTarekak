import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_search/data/repo/search_repo_im.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'search_state.dart';

class SearchCubit extends SafeCubit<SearchState> {
  final SearchRepoIm repoIm;
  SearchCubit(this.repoIm) : super(SearchInitial());

  Future<void> search(String sourcelat, String sourcelng, String destlat, String destlng,
      String departureDate, int seatsRequired) async {
    emit(SearchLoading());
    final response = await repoIm.search(
        sourcelat, sourcelng, destlat, destlng, departureDate, seatsRequired);

    response.fold((erorr) {
      emit(SearchErorr(
        error: HandelErorrMessage.search(erorr.message),
        needsVerification:
            HandelErorrMessage.isPassengerNotVerified(erorr.message),
      ));
    }, (listTrip) {
      emit(SearchSucces(trips: listTrip));
    });
  }
}
