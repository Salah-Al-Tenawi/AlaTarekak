import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/core/utils/functions/get_userid.dart';
import 'package:alatarekak/features/profiles/data/date_source/profile_local_data_source.dart';
import 'package:alatarekak/features/vieryfiy_user/data/data_source/verifit_user_remote_data_source.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';

class VerfiYUserRepo {
  final VerifitUserRemoteDataSource verifitUserRemoteDataSource;

  VerfiYUserRepo({required this.verifitUserRemoteDataSource});

  /// رفع الطلب ينقل حالة التوثيق في الخادم إلى «قيد المراجعة»، فنُسقط
  /// نسخة الملف المخزّنة محلياً ليُجلب بحالته الجديدة عند أول عرض —
  /// وإلا بقيت الشارة غائبة وبقي زرّ رفع طلب جديد متاحاً فوق طلب معلّق.
  Future<void> _invalidateCachedProfile() async {
    final id = myid();
    if (id != null) await ProfileLocalDataSourceIm().clearProfile(id);
  }

  Future<Either<Filuar, VerifiyUserModle>> verfiyDriver(
      XFile? faceIdPic,
      XFile? backIdPic,
      XFile? drivingLicensePic,
      XFile? mechanicCardPic) async {
    try {
      final response = await verifitUserRemoteDataSource.checkUpDriver(
          faceIdPic, backIdPic, drivingLicensePic, mechanicCardPic);
      await _invalidateCachedProfile();
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }



  Future <Either <Filuar ,VerifiyUserModle>> verfiyPassanger (XFile ?faceIdPic, XFile? backIdPic)async{ 
try {
      final response = await verifitUserRemoteDataSource.checkUpPassenger(
          faceIdPic, backIdPic,);
      await _invalidateCachedProfile();
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
