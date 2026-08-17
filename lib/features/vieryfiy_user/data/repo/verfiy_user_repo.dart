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
  /// فشل مسح الكاش لا يقلب رفعاً ناجحاً فشلاً.
  ///
  /// المستندات وصلت الخادم فعلاً حين نبلغ هنا. ولو رمى الكاش (صندوق
  /// مغلق، قرص ممتلئ) لعاد للمستخدم «فشل الرفع» وأعاد الإرسال بلا داعٍ —
  /// وأسوأ منه: قبل هذا الحارس كان الاستثناء يخرج غير ملتقَط فتنهار
  /// الشاشة **بعد** نجاح الرفع.
  ///
  /// أسوأ ما يقع بابتلاعه: تبقى شارة التوثيق قديمة حتى أول تحديث للملف.
  Future<void> _invalidateCachedProfile() async {
    try {
      final id = myid();
      if (id != null) await ProfileLocalDataSourceIm().clearProfile(id);
    } catch (_) {}
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
    } catch (e) {
      // كل ما ليس ServerExpcptions كان يخرج من هنا غير ملتقَط فتنهار
      // الشاشة عند الضغط على «إرسال»: تفكيك ردّ غير متوقَّع، أو تعذّر
      // مسح كاش الملف الشخصي. أياً كان السبب فالانهيار ليس جواباً —
      // تُترجَم الرسالة عربياً في الكيوبت وتُعرض للمستخدم.
      return left(Filuar(message: e.toString()));
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
    } catch (e) {
      return left(Filuar(message: e.toString()));
    }
  }
}
