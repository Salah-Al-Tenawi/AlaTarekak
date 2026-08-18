
import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/profiles/data/model/rating_modle.dart';
import 'package:alatarekak/features/profiles/domain/entity/comment_entity.dart';
import 'package:alatarekak/features/profiles/domain/entity/profile_entity.dart';

abstract class ProfileRepo {
  /// آخر نسخة مخزَّنة من الملف — متاحة فوراً وبلا شبكة، `null` إن لم
  /// يُخزَّن شيء بعد.
  ///
  /// كان الكاش احتياطاً عند فشل الشبكة **فقط**: كل فتح لتبويب «حسابي»
  /// يبدأ بمؤشّر تحميل وينتظر الخادم، رغم أن النسخة المخزَّنة جاهزة.
  ProfileEntity? getCachedProfile(int userid);

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
      String? address,
      {String? firstName,
      String? lastName});

  Future<Either<Filuar, CommentEntity>> addcommit(String commit, int userid);
  Future<Either<Filuar, RatingModle>> rateUser(double rating, int userId);
}
