import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

abstract class BookingUserInTripRepo {
  /// الرحلة وحجوزاتها من `GET /rides/{id}/passangers`.
  Future<Either<Filuar, TripModel>> tripPassengers(int rideId);

  Future<Either<Filuar, dynamic>> acceptPassanger(int bookingId);
  Future<Either<Filuar, dynamic>> rejectPassanger(int bookingId);
  Future<Either<Filuar, dynamic>> passengerNoShow(int bookingId);
}
