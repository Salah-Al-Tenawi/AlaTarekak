import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:alatarekak/core/errors/excptions.dart';
import 'package:alatarekak/core/errors/filuar.dart';
import 'package:alatarekak/features/vieryfiy_user/data/data_source/verifit_user_remote_data_source.dart';
import 'package:alatarekak/features/vieryfiy_user/data/model/verifiy_user_modle.dart';

class VerfiYUserRepo {
  final VerifitUserRemoteDataSource verifitUserRemoteDataSource;

  VerfiYUserRepo({required this.verifitUserRemoteDataSource});

  Future<Either<Filuar, VerifiyUserModle>> verfiyDriver(
      XFile? faceIdPic,
      XFile? backIdPic,
      XFile? drivingLicensePic,
      XFile? mechanicCardPic) async {
    try {
      final response = await verifitUserRemoteDataSource.checkUpDriver(
          faceIdPic, backIdPic, drivingLicensePic, mechanicCardPic);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  } 



  Future <Either <Filuar ,VerifiyUserModle>> verfiyPassanger (XFile ?faceIdPic, XFile? backIdPic)async{ 
try {
      final response = await verifitUserRemoteDataSource.checkUpPassenger(
          faceIdPic, backIdPic,);
      return right(response);
    } on ServerExpcptions catch (e) {
      return left(e.error);
    }
  }
}
