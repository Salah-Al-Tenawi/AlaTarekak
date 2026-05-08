import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/data/repo/trip_me_repo_im.dart';

part 'trip_me_state.dart';

class TripMeCubit extends Cubit<TripMeState> {
  final TripMeRepoIm _tripMeRepoIm;
  TripMeCubit(this._tripMeRepoIm) : super(TripMeInitial());

  Future getMeTrips() async {
    emit(TripMeLoading());
    final response = await _tripMeRepoIm.showAllTrip();
    response.fold((erorr) {
      emit(TripMeErorr(message: erorr.message));
    }, (trips) {
      emit(TripMeListLoaded(trips: trips));
    });
  }

  Future showOneTrip(int tripId) async {
    emit(TripMeLoading());
    final response = await _tripMeRepoIm.showOneTrip(tripId);
    response.fold((erorr) {
      emit(TripMeErorr(message: erorr.message));
    }, (trip) {
      emit(TripMeOneLoaded(trip: trip));
    });
  }

  Future cancelTrip(int tripId) async {
    emit(TripMeLoading());
    final response = await _tripMeRepoIm.cancelTrip(tripId);
    response.fold((erorr) {
      emit(TripMeErorr(message: erorr.message));
    }, (response) {
      emit(const TripMeCancel(message: "تم الغاء الرحلة بنجاح"));
      getMeTrips();
    });
  }

  void refrch() {
    emit(TripMeLoading());
  }

  }
