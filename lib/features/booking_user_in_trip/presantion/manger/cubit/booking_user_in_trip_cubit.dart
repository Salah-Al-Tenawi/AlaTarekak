import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:alatarekak/core/errors/handel_erorr_message.dart';
import 'package:alatarekak/features/booking_user_in_trip/data/repo/booking_users_in_trip_repo_imp.dart';

part 'booking_user_in_trip_state.dart';

class BookingUserInTripCubit extends Cubit<BookingUserInTripState> {
  final BookingUsersInTripRepoImp repo;

  BookingUserInTripCubit(this.repo) : super(BookingUserInTripInitial());

  Future<void> acceptPassanger(int bookingId) async {
    emit(BookingUserInTripLoading());

    final response = await repo.acceptPassanger(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(
          message: HandelErorrMessage.acceptPassanger(error.message))),
      (succ) {
        emit(BookingUserInTripUpdated(
          bookingId: bookingId,
          statusRide: succ.statusRide,
        ));
      },
    );
  }

  Future<void> rejectPassanger(int bookingId) async {
    emit(BookingUserInTripLoading());

    final response = await repo.rejectPassanger(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(
          message: HandelErorrMessage.rejectPassanger(error.message))),
      (_) {
        // استجابة الرفض لا تعيد حالة رحلة — الحجز أصبح مرفوضاً
        emit(BookingUserInTripUpdated(
          bookingId: bookingId,
          statusRide: "rejected",
        ));
      },
    );
  }

  /// بلاغ السائق أن الراكب لم يحضر
  Future<void> passengerNoShow(int bookingId) async {
    emit(BookingUserInTripLoading());

    final response = await repo.passengerNoShow(bookingId);
    response.fold(
      (error) => emit(BookingUserInTripErorr(
          message: HandelErorrMessage.passengerNoShow(error.message))),
      (_) => emit(BookingUserInTripUpdated(
        bookingId: bookingId,
        statusRide: "passenger_no_show",
      )),
    );
  }
}
