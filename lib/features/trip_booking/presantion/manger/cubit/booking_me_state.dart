part of 'booking_me_cubit.dart';

sealed class BookingMeState extends Equatable {
  const BookingMeState();

  @override
  List<Object> get props => [];
}

final class BookingMeInitial extends BookingMeState {}

final class BookingMeListloading extends BookingMeState {}

final class BookingMeloading extends BookingMeState {}
final class BookingMeButtonloading extends BookingMeState {}

final class BookingMeErorr extends BookingMeState {
  final String message;

  const BookingMeErorr({required this.message});
}

final class BookingMeListLoaded extends BookingMeState {
  final List<BookingMe> bookings;
  const BookingMeListLoaded({required this.bookings});
}

final class BookingMeCanceled extends BookingMeState {
  final CancelBookingModel cancelModel ;

  const BookingMeCanceled({required this.cancelModel});
}

final class BookingMeFinish extends BookingMeState {
  final String message;

  const BookingMeFinish({required this.message});
}


final class BookingMeRated extends BookingMeState {
  final double rate;

  const BookingMeRated({required this.rate});
}

final class BookingMeCommented extends BookingMeState {}
