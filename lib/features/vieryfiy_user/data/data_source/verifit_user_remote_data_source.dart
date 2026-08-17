import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/api/api_end_points.dart';
import 'package:alatarekak/core/api/dio_consumer.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/utils/functions/get_token.dart';
import 'package:alatarekak/core/utils/functions/upload_file_to_api.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';

class VerifitUserRemoteDataSource {
  final DioConSumer api;

  VerifitUserRemoteDataSource({required this.api});

  /// رد رفع المستندات.
  ///
  /// كان السطر `VerifiyUserModle.fromJson(response)` تحويلاً ضمنياً من
  /// `dynamic` إلى `Map<String, dynamic>`: يرمي `TypeError` على أي رد ليس
  /// كائن JSON — جسم فارغ (201 بلا محتوى)، أو مصفوفة، أو نصّ. والـ
  /// `TypeError` **ليس** `ServerExpcptions`، فيمرّ من فوق `catch` في
  /// المستودع ويخرج غير ملتقَط: تنهار الشاشة عند الضغط على «إرسال».
  ///
  /// ولا نطالب بـ `success` صريحة: المسار قد لا يرسلها، ومطالبته بها تقلب
  /// الرفع الناجح فشلاً. وصول الرد بلا استثناء يعني 2xx — ولا نرفض إلا
  /// حين يقول الخادم **صراحةً** إنه فشل.
  VerifiyUserModle _parse(dynamic json) {
    if (json is Map && (json['success'] == false || json['status'] == 'error')) {
      throw ServerExpcptions(
        error: json is Map<String, dynamic>
            ? Filuar.fromJson(json)
            : const Filuar(message: 'حدث خطأ غير متوقع'),
      );
    }
    return VerifiyUserModle();
  }

  Future<VerifiyUserModle> checkUpPassenger(
      XFile? faceIdPic, XFile? backIdPic) async {
    final response =
        await api.post(ApiEndPoint.verifypassenger, isFomrData: true, header: {
      ApiKey.authorization: "Bearer ${mytoken()}"
    }, data: {
      ApiKey.faceIdPic: await uploadFiletoApi(faceIdPic),
      ApiKey.backIdPic: await uploadFiletoApi(backIdPic),
    });
    return _parse(response);
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
    return _parse(response);
  }
}
