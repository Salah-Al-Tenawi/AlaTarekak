part of 'tripsearch_list_cubit.dart';

sealed class TripsearchListState extends Equatable {
  const TripsearchListState();

  @override
  List<Object> get props => [];
}

final class TripsearchListInitial extends TripsearchListState {}

final class TripsearchListLoading extends TripsearchListState {}

final class TripsearchListEroor extends TripsearchListState {
  final String message;

  const TripsearchListEroor({required this.message});
}

final class TripsearchListLoaded extends TripsearchListState {
 final List<TripModel> trips;

  const TripsearchListLoaded({required this.trips});
}
