part of 'tripdetails_cubit.dart';

sealed class TripDetailsState extends Equatable {
  const TripDetailsState();

  @override
  List<Object?> get props => [];
}

final class TripDetailsInitial extends TripDetailsState {}

final class TripDetailsLoading extends TripDetailsState {}

final class TripDetailsError extends TripDetailsState {
  final String message;
  const TripDetailsError({required this.message});

  @override
  List<Object?> get props => [message];
}

final class TripDetailsLoaded extends TripDetailsState {
  final TripModel trip;
  final TripDetailsMode mode;
  const TripDetailsLoaded({required this.trip, required this.mode});

  @override
  List<Object?> get props => [trip, mode];
}

final class TripDetailsCancel extends TripDetailsState {
  final String message;
  const TripDetailsCancel({required this.message});

  @override
  List<Object?> get props => [message];
}

final class TripDetailsBooking extends TripDetailsState {}

  final class TripDetailsRequestBooking extends TripDetailsState {
    final BookingResponse booking;
    const TripDetailsRequestBooking({required this.booking});

    @override
    List<Object?> get props => [booking];
  }

final class TripDetailsGoToProfile extends TripDetailsState {
  final int userId;
  const TripDetailsGoToProfile({required this.userId});

  @override
  List<Object?> get props => [userId];
}

final class TripDetailsGoToChat extends TripDetailsState {
  final int driverId;
  const TripDetailsGoToChat({required this.driverId});

  @override
  List<Object?> get props => [driverId];
}

class TripDetailsButtonLoading extends TripDetailsState {}
class TripDetailsFinishTrip extends TripDetailsState {}

class TripDetailsBookingSuccess extends TripDetailsState {
  final String message;

  const TripDetailsBookingSuccess({required this.message});
}

class TripDetailsBookingFailure extends TripDetailsState {
  final String message;

  const TripDetailsBookingFailure({required this.message});
}