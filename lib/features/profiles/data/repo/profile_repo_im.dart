
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/profiles/data/date_source/profile_local_data_source.dart';
import 'package:alatarekak/features/profiles/data/date_source/profile_remote_date_source.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';
import 'package:alatarekak/features/profiles/domain/repo/profile_rep.dart';

class ProfileRepoIm extends ProfileRepo {
  final ProfileRemoteDateSourceIm profileRemoteDateSourceIm;
  final ProfileLocalDataSourceIm profileLocalDataSourceIm;

  ProfileRepoIm({
    required this.profileRemoteDateSourceIm,
    required this.profileLocalDataSourceIm,
  });

  @override
  Future<Either<Filuar, CommentEntity>> addcommit(
      String commit, int userid, int rideId) async {
    try {
      final response =
          await profileRemoteDateSourceIm.addcommit(commit, userid, rideId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  @override
  Future<Either<Filuar, RatingModle>> rateUser(
      double rating, int userId, int rideId) async {
    try {
      final response =
          await profileRemoteDateSourceIm.rateUser(rating, userId, rideId);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }

  /// الشبكة أولاً والكاش احتياطي عند تعذّرها.
  ///
  /// كان الكاش يُقرأ أولاً ويُعاد فوراً بلا أي اتصال بالخادم، ولمّا كان
  /// لا يُبطَل في أي موضع (`clearProfile` لم تكن تُستدعى إطلاقاً) كانت
  /// نسخة أول تحميل تبقى إلى الأبد. فأي تغيّر يقع في الخادم — وأهمّه
  /// حالة التوثيق حين تنتقل إلى «قيد المراجعة» أو يبتّ فيها الأدمن —
  /// لا يصل التطبيق أبداً: لا تظهر شارة الحالة، ويظلّ المستخدم قادراً
  /// على رفع طلب توثيق جديد فوق طلبٍ معلّق.
  @override
  ProfileEntity? getCachedProfile(int userid) {
    try {
      return profileLocalDataSourceIm.getProfile(userid);
    } catch (_) {
      // كاش تالف أو صندوق غير مفتوح — لا يمنع فتح الشاشة
      return null;
    }
  }

  @override
  Future<Either<Filuar, ProfileEntity>> showProfile(int userid) async {
    try {
      final profile = await profileRemoteDateSourceIm.showProfile(userid);
      await profileLocalDataSourceIm.saveProfile(userid, profile);
      return right(profile);
    } on ServerExpcptions catch (e) {
      // تعذّرت الشبكة — نعرض آخر نسخة معروفة بدل شاشة خطأ فارغة
      final cached = profileLocalDataSourceIm.getProfile(userid);
      if (cached != null) return right(cached);
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
      String? address,
      {String? firstName,
      String? lastName}) async {
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
          address,
          firstName: firstName,
          lastName: lastName);
      await profileLocalDataSourceIm.saveProfile(profile.data.userId, profile);
      return right(profile);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
