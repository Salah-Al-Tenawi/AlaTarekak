
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/core/utils/functions/upload_file_to_api.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';

class VerifitUserRemoteDataSource {
  final DioConSumer api;

  VerifitUserRemoteDataSource({required this.api});

  Future<VerifiyUserModle> checkUpPassenger(
      XFile? faceIdPic, XFile? backIdPic) async {
    final response =
        await api.post(ApiEndPoint.verifypassenger, isFomrData: true, header: {
      ApiKey.authorization: "Bearer ${mytoken()}"
    }, data: {
      ApiKey.faceIdPic: await uploadFiletoApi(faceIdPic),
      ApiKey.backIdPic: await uploadFiletoApi(backIdPic),
    });
    return VerifiyUserModle.fromJson(response);
  }

  Future<VerifiyUserModle> checkUpDriver(XFile? faceIdPic, XFile? backIdPic,
      XFile? drivingLicensePic, XFile? mechanicCardPic) async {
    final response =
        await api.post(ApiEndPoint.verifydriver, isFomrData: true, header: {
      ApiKey.authorization: "Bearer ${mytoken()}"
    }, data: {
      ApiKey.faceIdPic: await uploadFiletoApi(faceIdPic),
      ApiKey.backIdPic: await uploadFiletoApi(backIdPic),
      ApiKey.licensePic: await uploadFiletoApi(drivingLicensePic),
      ApiKey.mechanicCardPic: await uploadFiletoApi(mechanicCardPic)
    });
    return VerifiyUserModle.fromJson(response);
  }
}
