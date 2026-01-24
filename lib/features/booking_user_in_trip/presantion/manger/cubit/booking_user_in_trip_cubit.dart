import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/model/booking_user_modle.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';

part 'booking_user_in_trip_state.dart';

class BookingUserInTripCubit extends Cubit<BookingUserInTripState> {
  final BookingUsersInTripRepoImp repo;

  BookingUserInTripCubit(this.repo) : super(BookingUserInTripInitial());

  acceptPassanger(int bookingId) async {
    emit(BookingUserInTripLoading());
    await Future.delayed(const Duration(seconds: 2));

    final response = await repo.acceptPassanger(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(message: error.message)),
      (succ) {
        emit(BookingUserInTripUpdated(
          bookingId: bookingId,
          statusRide: succ.statusRide,
        ));
      },
    );
  }

  rejectPassanger(int bookingId) async {
    emit(BookingUserInTripLoading());
    await Future.delayed(const Duration(seconds: 2));

    final response = await repo.rejectPassanger(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(message: error.message)),
      (succ) {
        emit(BookingUserInTripUpdated(
          bookingId: bookingId,
          statusRide: "succ.statusRide",
        ));
      },
    );
  }
}
