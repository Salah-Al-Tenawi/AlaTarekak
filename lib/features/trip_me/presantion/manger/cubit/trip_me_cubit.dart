import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/data/repo/trip_me_repo_im.dart';
import 'package:alatarekak/core/service/safe_cubit.dart';

part 'trip_me_state.dart';

class TripMeCubit extends SafeCubit<TripMeState> {
  final TripMeRepoIm _tripMeRepoIm;
  TripMeCubit(this._tripMeRepoIm) : super(TripMeInitial());

  Future getMeTrips() async {
    emit(TripMeLoading());
    final response = await _tripMeRepoIm.showAllTrip();
    response.fold((erorr) {
      emit(TripMeErorr(message: erorr.arabic(HandelErorrMessage.showAllride)));
    }, (trips) {
      emit(TripMeListLoaded(trips: trips));
    });
  }

  Future cancelTrip(int tripId) async {
    emit(TripMeLoading());
    final response = await _tripMeRepoIm.cancelTrip(tripId);
    response.fold((erorr) {
      emit(TripMeErorr(message: erorr.arabic(HandelErorrMessage.cancelRide)));
    }, (response) {
      emit(const TripMeCancel(message: "تم الغاء الرحلة بنجاح"));
      getMeTrips();
    });
  }

  void refrch() {
    emit(TripMeLoading());
  }

  }
