import 'package:alatarekak/core/api/api_end_points.dart';

class DocumentsModel  {
  final String? faceIdPic;
  final String ?backIdPic;
  final String? licensePic;
  final String? mechanicCardPic;

  DocumentsModel({
    this.faceIdPic,
    this.backIdPic,
    this.licensePic,
    this.mechanicCardPic,
  });

  factory DocumentsModel.fromJson(Map<String, dynamic> json) {
    return DocumentsModel(
      faceIdPic: json[ApiKey.faceIdPic],
      backIdPic: json[ApiKey.backIdPic],
      licensePic: json[ApiKey.licensePic],
      mechanicCardPic: json[ApiKey.mechanicCardPic],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.faceIdPic: faceIdPic,
      ApiKey.backIdPic: backIdPic,
      ApiKey.licensePic: licensePic,
      ApiKey.mechanicCardPic: mechanicCardPic,
    };
  }
}