part of 'booking_user_in_trip_cubit.dart';

sealed class BookingUserInTripState extends Equatable {
  const BookingUserInTripState();

  @override
  List<Object> get props => [];
}

final class BookingUserInTripInitial extends BookingUserInTripState {}

final class BookingUserInTripLoading extends BookingUserInTripState {}

final class BookingUserInTripErorr extends BookingUserInTripState {
  final String message;

  const BookingUserInTripErorr({required this.message});
}

final class BookingUserInTripUpdated extends BookingUserInTripState {
  final int bookingId;
  final String statusRide;

  const BookingUserInTripUpdated({
    required this.bookingId,
    required this.statusRide,
  });

  @override
  List<Object> get props => [bookingId, statusRide];
}

final class BookingUserInTripSucc extends BookingUserInTripState {}

