import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';

abstract class VerifiyUserRepo{ 
Future<Either<Filuar , VerifiyUserModle>>  checkUpPassenger( XFile faceIdPic ,XFile backIdPic );
Future<Either<Filuar , VerifiyUserModle>>  checkUpDriver  ( XFile faceIdPic ,XFile backIdPic , XFile drivingLicensePic , XFile mechanicCardPic );

}