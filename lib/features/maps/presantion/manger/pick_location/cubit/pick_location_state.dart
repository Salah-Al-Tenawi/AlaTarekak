part of 'pick_location_cubit.dart';

abstract class PickLocationState extends Equatable {
  const PickLocationState();

  @override
  List<Object?> get props => [];
}

class PickLocationInitial extends PickLocationState {}

class PickLocationLoading extends PickLocationState {
  final LatLng point;

  const PickLocationLoading(this.point);

  @override
  List<Object?> get props => [point];
}

class PickLocationLoaded extends PickLocationState {
  final LatLng point;
  final String placeName;

  const PickLocationLoaded({required this.point, required this.placeName});

  @override
  List<Object?> get props => [point, placeName];
}

class PickLocationError extends PickLocationState {
  final LatLng point;
  final String message;

  const PickLocationError({required this.point, required this.message});

  @override
  List<Object?> get props => [point, message];
}
