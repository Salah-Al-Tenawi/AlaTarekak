import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_details/data/model/trip_details_mode.dart';
import 'package:alatarekak/features/trip_details/data/repo/trip_details_repo.dart';

part 'tripdetails_state.dart';

class TripDetailsCubit extends Cubit<TripDetailsState> {
  final TripDetailsRepoIM tripDetailsRepoIM;

  TripDetailsCubit({required this.tripDetailsRepoIM})
      : super(TripDetailsInitial());

  Future<void> booking(int seats, int tripId, String communicationNumber) async {
    emit(TripDetailsLoading());
    final response =
        await tripDetailsRepoIM.booking(seats, tripId, communicationNumber);
    response.fold((error) {
      emit(TripDetailsError(message: error.message));
    }, (booking) {
      emit(TripDetailsRequestBooking(booking: booking));
    });
  }

  Future<void> fetchTrip(int tripId) async {
    emit(TripDetailsLoading());
    final response = await tripDetailsRepoIM.featchTrip(tripId);
    response.fold((error) {
      emit(TripDetailsError(message: error.message));
    }, (trip) {
      if (trip.driver.id == myid()) {
        emit(TripDetailsLoaded(trip: trip, mode: TripDetailsMode.myView));
      } else {
        emit(TripDetailsLoaded(trip: trip, mode: TripDetailsMode.otherView));
      }
    });
  }

  Future<void> fetchProfile(int userId) async {
    emit(TripDetailsGoToProfile(userId: userId));
  }

  void gotoChatWithDriver(int userId) {
    emit(TripDetailsGoToChat(driverId: userId));
  }

  Future<void> finishRide(int tripId) async {
    emit(TripDetailsLoading());
    final response = await tripDetailsRepoIM.finishTrip(tripId);
    response.fold((erorr) {
      emit(TripDetailsError(message: erorr.message));
    }, (response) {
      emit(TripDetailsFinishTrip());
    });
  }

  Future<void> finishAndConfirmRide(int tripId) async {
    emit(TripDetailsLoading());
    final response = await tripDetailsRepoIM.finishTrip(tripId);
    response.fold((erorr) {
      emit(TripDetailsError(message: erorr.message));
    }, (response) async {
      final response = await tripDetailsRepoIM.confirmTrip(tripId);
      response.fold((erorr) {
        emit(TripDetailsError(message: erorr.message));
      }, (succ) {
        emit(TripDetailsFinishTrip());
      });
    });
  }
}
