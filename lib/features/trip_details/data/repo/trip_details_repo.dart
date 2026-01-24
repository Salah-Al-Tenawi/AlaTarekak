import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_booking/data/model/booking_me_model.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_details/data/data_source/trip_details_remote_data_source.dart';
import 'package:alatarekak/features/trip_details/data/model/booking_model.dart';
import 'package:alatarekak/features/trip_details/domain/repo/trip_details_repo.dart';

class TripDetailsRepoIM extends TripDetailsRepo {
  final TripDetailsRemoteDataSource remoteDataSource;

  TripDetailsRepoIM({required this.remoteDataSource});

  @override
  Future<Either<Filuar, TripModel>> featchTrip(int tripId) async {
    try {
      final response = await remoteDataSource.featchTrip(tripId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  Future<Either<Filuar, BookingResponse>> booking(
      int seats, int tripId, String communicationNumber) async {
    try {
      final response = await remoteDataSource.booking(seats, tripId ,communicationNumber);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
  
  @override
  Future<Either<Filuar, dynamic>> confirmTrip(int tripId) async{
     try {
      final response = await remoteDataSource.confirmTrip(tripId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
    
  }
  
  
  @override
  Future<Either<Filuar, dynamic>> finishTrip(int tripId) async{ 
    try {
      final response = await remoteDataSource.finishTrip(tripId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
    
    
  } 

}
