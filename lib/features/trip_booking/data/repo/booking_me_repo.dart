import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';
import 'package:alatarekak/features/trip_booking/data/data%20source/booking_remote_data_source.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_booking/data/model/cancel_booking_model.dart';

class BookingMeRepo {
  final BookingRemoteDataSource _remoteDataSource;

  BookingMeRepo({required BookingRemoteDataSource remoteDataSource})
      : _remoteDataSource = remoteDataSource;

  Future<Either<Filuar, List<BookingMe>>> getMeBooking() async {
    try {
      final bookings = await _remoteDataSource.getMeBooking();
      return Right(bookings);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

// todo Modeling
  Future<Either<Filuar, CancelBookingModel>> cancelBooking(
      int bookingId, int seats) async {
    try {
      final response = await _remoteDataSource.cancelBooking(bookingId, seats);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  Future<Either<Filuar, dynamic>> finshTrip(int bookingId) async {
    try {
      final response = await _remoteDataSource.finishRide(bookingId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  } 
  Future<Either<Filuar, CommentEntity>> addcommit(
      String commit, int userid) async {
    try {
      final response =
          await _remoteDataSource.addcommit(commit, userid);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  Future<Either<Filuar, RatingModle>> rateUser(
      double rating, int userId) async {
    try {
      final response = await _remoteDataSource.rateUser(rating, userId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
