
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/profiles/data/date_source/profile_remote_date_source.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/domain/repo/profile_rep.dart';

class ProfileRepoIm extends ProfileRepo {
  final ProfileRemoteDateSourceIm profileRemoteDateSourceIm;

  ProfileRepoIm({required this.profileRemoteDateSourceIm});

  @override
  Future<Either<Filuar, CommentEntity>> addcommit(
      String commit, int userid) async {
    try {
      final response =
          await profileRemoteDateSourceIm.addcommit(commit, userid);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, RatingModle>> rateUser(
      double rating, int userId) async {
    try {
      final response = await profileRemoteDateSourceIm.rateUser(rating, userId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, ProfileEntity>> showProfile(int userid) async {
    try {
      final profile = await profileRemoteDateSourceIm.showProfile(userid);
      return right(profile);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
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
      String? address) async {
    try {
      final profile = await profileRemoteDateSourceIm.updateProfile(
          profilePhoto,
          description,
          colorOfCar,
          numberOfSeats,
          carPic,
          radio,
          smoking,
          faceIdPic,
          backIdPic,
          drivingLicPic,
          mechanieCardPic,
          typeOfCar,
          gender,
          address);
      return right(profile);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
