import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

abstract class TripCreateRepo {
  Future<Either<Filuar, TripModel>> createTrip(
    String startLat,
    String startLng,
    String endLat,
    String endLng,
    String date,
    int seats,
    int price,
    String? notes,
    int routeIndex,
    String paymentMethod, 
    String bookingType, 
    String communicationNumber
  );
}
