part of 'trip_me_cubit.dart';

sealed class TripMeState extends Equatable {
  const TripMeState();

  @override
  List<Object> get props => [];
}

final class TripMeInitial extends TripMeState {}

final class TripMeLoading extends TripMeState {}

final class TripMeListLoaded extends TripMeState {
  final List<TripModel> trips;

  const TripMeListLoaded({required this.trips});
}

final class TripMeOneLoaded extends TripMeState {
  final TripModel trip;

  const TripMeOneLoaded({required this.trip});
}

final class TripMeErorr extends TripMeState {
  final String message;

  const TripMeErorr({required this.message});
}

final class TripMeCancel extends TripMeState {
  final String message;
  const TripMeCancel( {required this.message});
}

final class TripMeFinishTrip extends TripMeState{ 
  
}
