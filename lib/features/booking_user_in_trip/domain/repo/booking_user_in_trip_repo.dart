import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';

abstract class BookingUserInTripRepo {
  Future<Either<Filuar, dynamic>> acceptPassanger(int bookingId);
  Future<Either<Filuar, dynamic>> rejectPassanger(int bookingId);
  
}
