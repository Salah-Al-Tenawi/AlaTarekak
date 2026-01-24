import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

abstract class TripDetailsRepo {
  Future<Either<Filuar, TripModel>> featchTrip(int tripId);
  Future<Either<Filuar, dynamic>> finishTrip(int tripId); 
  Future<Either<Filuar, dynamic>> confirmTrip(int tripId); 
  
}
