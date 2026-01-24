import 'package:dartz/dartz.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/trip_create/data/data_source/trip_create_remote_data_source.dart';
import 'package:alatarekak/features/trip_create/data/model/trip_model.dart';
import 'package:alatarekak/features/trip_create/domin/repo/trip_create_repo.dart';

class TripCreateRepoIm extends TripCreateRepo {
  final TripCreateRemoteDataSource tripCreateRemoteDataSource;

  TripCreateRepoIm({required this.tripCreateRemoteDataSource});
  @override
  Future<Either<Filuar, TripModel>> createTrip(String startLat,
  String startLng ,String endLat ,String endLng ,
       String date, int seats, int price ,
    String? notes,
    int routeIndex,
    String paymentMethod, String bookingType ,String communicationNumber
    
    
    ) async {
    try {
      final response = await tripCreateRemoteDataSource.createTrip(
          startLat ,startLng ,endLat ,endLng, date, seats, price , notes ,routeIndex ,paymentMethod ,bookingType ,communicationNumber) ;
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
