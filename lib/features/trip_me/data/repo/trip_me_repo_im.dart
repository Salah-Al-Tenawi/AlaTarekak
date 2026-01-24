import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_me/data/data%20source/trip_me_remote_data_source.dart';
import 'package:alatarekak/features/trip_me/domain/repo/trip_me_repo.dart';

class TripMeRepoIm extends TripMeRepo {
  final TripMeRemoteDataSource _tripMeRemoteDataSource;

  TripMeRepoIm({required TripMeRemoteDataSource tripMeRemoteDataSource})
      : _tripMeRemoteDataSource = tripMeRemoteDataSource;

  @override
  Future<Either<Filuar, dynamic>> cancelTrip(int tripId) async {
    try {
      final response = await _tripMeRemoteDataSource.cancelTrip(tripId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, List<TripModel>>> showAllTrip() async{
     try {
      final response = await _tripMeRemoteDataSource.getMyTrip();
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, TripModel>> showOneTrip(int tripId)async {
     try {
      final response = await _tripMeRemoteDataSource.showOneTrip(tripId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
    
  }
  

}
