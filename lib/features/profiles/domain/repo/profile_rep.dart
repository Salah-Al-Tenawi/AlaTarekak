
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

abstract class ProfileRepo {
  Future<Either<Filuar, ProfileEntity>> showProfile(int userid);
  
  Future<Either<Filuar, ProfileEntity>> updateProfile(
      XFile? profilePhoto,
      String? description,
      String? colorOfCar,
      int? numberOfSeats,
      XFile? carPic,
      int? radio,
      int? smoking,
      XFile? faceIdPic,
      XFile? backIdPic,
      XFile? drivingLicPic,
      XFile? mechanieCardPic,
      String? typeOfCar,
      String? gender,
      String? address);

  Future<Either<Filuar, CommentEntity>> addcommit(String commit, int userid);
  Future<Either<Filuar, RatingModle>> rateUser(double rating, int userId);
}
