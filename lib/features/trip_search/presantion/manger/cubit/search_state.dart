part of 'search_cubit.dart';

sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

final class SearchInitial extends SearchState {}

final class SearchLoading extends SearchState {}

final class SearchSucces extends SearchState {
  final List<TripModel> trips;

  const SearchSucces({required this.trips});
}

final class SearchErorr extends SearchState {
  final String error;

  const SearchErorr({required this.error});
}

