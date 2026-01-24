import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

abstract class TripMeRepo {
  Future<Either<Filuar, List<TripModel>>> showAllTrip();
  Future<Either<Filuar, TripModel>> showOneTrip(int tripId);
  Future<Either<Filuar, dynamic>> cancelTrip(int tripId); 
  
  
}
