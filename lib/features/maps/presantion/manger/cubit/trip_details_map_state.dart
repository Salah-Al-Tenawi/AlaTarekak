part of 'trip_details_map_cubit.dart';

abstract class TripDetailsMapState extends Equatable {
  const TripDetailsMapState();

  @override
  List<Object> get props => [];
}

class TripDetailsMapInitial extends TripDetailsMapState {}

class TripDetailsMapLoading extends TripDetailsMapState {}

class TripDetailsMapLoaded extends TripDetailsMapState {
  final List<LatLng> path;
  const TripDetailsMapLoaded(this.path);

  @override
  List<Object> get props => [path];
}

class TripDetailsMapError extends TripDetailsMapState {
  final String message;
  const TripDetailsMapError(this.message);

  @override
  List<Object> get props => [message];
}
