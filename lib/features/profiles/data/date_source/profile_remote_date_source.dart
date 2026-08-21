
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/core/utils/functions/upload_file_to_api.dart';
import 'package:alatarekak/features/profiles/data/model/comment_model.dart';
import 'package:alatarekak/features/profiles/data/model/profile_model.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';

abstract class ProfileRemoteDateSource {
  final DioConSumer api;

  ProfileRemoteDateSource({required this.api});
  Future<ProfileModel> showProfile(int id);
  Future<ProfileModel> updateProfile(
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
      String? address,
      {String? firstName,
      String? lastName});

  Future<CommentModel> addcommit(String commit, int userid, int rideId);
  Future<RatingModle> rateUser(double rating, int userId, int rideId);
}

class ProfileRemoteDateSourceIm extends ProfileRemoteDateSource {
  ProfileRemoteDateSourceIm({required super.api});

  @override
  Future<ProfileModel> showProfile(int id) async {
    final response = await api.get("${ApiEndPoint.profile}/$id",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"});

    return ProfileModel.fromJson(response);
  }

  @override
  Future<CommentModel> addcommit(
      String commit, int userId, int rideId) async {
    final response = await api.post("${ApiEndPoint.profile}/$userId/comments",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"},
        data: {ApiKey.comment: commit, ApiKey.rideId: rideId});

    return CommentModel.fromJson(response);
  }

  @override
  Future<ProfileModel> updateProfile(
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
      String? address,
      {String? firstName,
      String? lastName}) async {
    final Map<String, dynamic> data = {
      ApiKey.profilePhoto: await uploadFiletoApi(profilePhoto),
      ApiKey.description: description,
      ApiKey.colorOfCar: colorOfCar,
      ApiKey.numberOfSeats: numberOfSeats,
      ApiKey.carPic: await uploadFiletoApi(carPic),
      ApiKey.radio: radio,
      ApiKey.smoking: smoking,
      ApiKey.faceIdPic: await uploadFiletoApi(faceIdPic),
      ApiKey.backIdPic: await uploadFiletoApi(backIdPic),
      ApiKey.drivingLicensePic: await uploadFiletoApi(drivingLicPic),
      ApiKey.mechanicCardPic: await uploadFiletoApi(mechanieCardPic),
      ApiKey.typeOfCar: typeOfCar,
      ApiKey.gender: gender,
      ApiKey.address: address,
      // الخادم يحفظ الاسم حقلين ويعيدهما مجموعين في full_name
      ApiKey.firstName: firstName,
      ApiKey.lastName: lastName,
    }..removeWhere((_, v) => v == null);

    final response = await api.post(ApiEndPoint.profile,
        header: {ApiKey.authorization: "Bearer ${mytoken()}"},
        isFomrData: true,
        data: data);
    return ProfileModel.fromJson(response);
  }

  @override
  Future<RatingModle> rateUser(
      double rating, int userId, int rideId) async {
    final response = await api.post("${ApiEndPoint.profile}/$userId/rate",
        header: {ApiKey.authorization: "Bearer ${mytoken()}"},
        data: {ApiKey.rating: rating, ApiKey.rideId: rideId});

    return RatingModle.fromJson(response);
  }
}
