import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';

abstract class BookingUserInTripRepo {
  /// الرحلة وحجوزاتها من `GET /rides/{id}/passengers`.
  Future<Either<Filuar, TripModel>> tripPassengers(int rideId);

  Future<Either<Filuar, dynamic>> acceptPassanger(int bookingId);
  Future<Either<Filuar, dynamic>> rejectPassanger(int bookingId);
  Future<Either<Filuar, dynamic>> passengerNoShow(int bookingId);

  /// تقييم راكب — `POST /profile/{userId}/rate`.
  Future<Either<Filuar, RatingModle>> rateUser(double rating, int userId);

  /// تعليق على راكب — `POST /profile/{userId}/comments`.
  Future<Either<Filuar, CommentEntity>> addcommit(String comment, int userId);
}
