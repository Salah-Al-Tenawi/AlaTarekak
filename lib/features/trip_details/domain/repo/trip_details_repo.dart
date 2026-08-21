import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

abstract class TripDetailsRepo {
  Future<Either<Filuar, TripModel>> featchTrip(int tripId);

  /// الرحلة وحجوزاتها — لسائقها وحده. انظر شرح التنفيذ.
  Future<Either<Filuar, TripModel>> featchTripWithBookings(int tripId);
  Future<Either<Filuar, dynamic>> finishTrip(int tripId);

  /// إلغاء السائق رحلته — متاحٌ من التفاصيل كما من القائمة.
  Future<Either<Filuar, dynamic>> cancelTrip(int tripId); 
  Future<Either<Filuar, dynamic>> confirmTrip(int tripId); 
  
}
