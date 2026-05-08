import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_search/data/data%20source/search_remote_data_source.dart';

class SearchRepoIm {
  final SearchRemoteDataSource searchRemoteDataSource;

  SearchRepoIm({required this.searchRemoteDataSource});

  Future<Either<Filuar, List<TripModel>>> search(
      String sourcelat,
      String sourcelng,
      String destlat,
      String destlng,
      String departureDate,
      int seatsRequired) async {
    try {
      final response = await searchRemoteDataSource.search(
          sourcelat, sourcelng, destlat, destlng, departureDate, seatsRequired);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  // Future<Either<Filuar, RequestBookingModel>> booking(
  //     int seats, int tripId) async {
  //   try {
  //     final response = await searchRemoteDataSource.booking(seats, tripId);
  //     return right(response);
  //   } on ServerExpcptions catch (e) {
  //     return left(e.error);
  //   }
  // }

  Future<Either<Filuar, TripModel>> showOneTrip(int tripId) async {
    try {
      final response = await searchRemoteDataSource.showOneTrip(tripId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
